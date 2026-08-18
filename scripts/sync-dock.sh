#!/usr/bin/env bash

# The Dock stage of the managed setup, and the only stage that no bootstrap hook
# calls. Every other part of this repository converges forward on its own, but a
# Dock is rearranged by hand between two setups, and a phase that ran inside
# `mise run setup` would replace that arrangement with whatever the manifest
# last captured. Both directions are explicit instead:
#
#   mise run dock:apply    rebuild the Dock from dock.txt
#   mise run dock:export   capture the running Dock into dock.txt
#
# `dock.txt` holds the Dock the way a person reads it: one line per tile, in
# Dock order, applications by path and stacks by folder. macOS stores much more
# than that per tile, including a bookmark blob that follows an application when
# it moves and a GUID that means nothing on a second Mac. None of that belongs
# in a public repository, and none of it survives a restore onto another
# machine. The Dock rebuilds every one of those fields from the path alone, so
# the path is all this keeps.

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${REPO_ROOT}/scripts/lib.sh"

readonly MANIFEST="${REPO_ROOT}/dock.txt"
readonly DOCK_DOMAIN="com.apple.dock"

# The Dock keeps applications and everything else in two separate arrays, and
# their order within each array is the order on screen.
readonly APPS_KEY="persistent-apps"
readonly OTHERS_KEY="persistent-others"

DRY_RUN=false
COMMAND=""
PRINT_ONLY=false
TEMPORARY_PLIST=""

cleanup() {
  if [[ -n "$TEMPORARY_PLIST" ]]; then
    rm -f "$TEMPORARY_PLIST"
  fi
}

trap cleanup EXIT

usage() {
  printf 'Usage: %s apply [--dry-run]\n' "${0##*/}"
  printf '       %s export [--print]\n' "${0##*/}"
}

for argument in "$@"; do
  case "$argument" in
    apply|export)
      if [[ -n "$COMMAND" ]]; then
        usage >&2
        exit 64
      fi
      COMMAND="$argument"
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --print)
      PRINT_ONLY=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$COMMAND" ]]; then
  usage >&2
  exit 64
fi

# Each direction takes the flag that means something for it. `export --dry-run`
# would suggest a preview that `--print` already is, and `apply --print` would
# suggest an output this direction does not have.
if [[ "$COMMAND" == export && "$DRY_RUN" == true ]] ||
  [[ "$COMMAND" == apply && "$PRINT_ONLY" == true ]]; then
  usage >&2
  exit 64
fi

# The three stack settings are stored as integers, and the manifest spells them
# out. A name survives a macOS release that renumbers a menu; a bare `showas =
# 1` in a text file does not tell anyone that the stack opens as a fan.
display_to_name() { case "$1" in 0) printf 'stack' ;; 1) printf 'folder' ;; *) printf '' ;; esac; }
name_to_display() { case "$1" in stack) printf '0' ;; folder) printf '1' ;; *) printf '' ;; esac; }

view_to_name() {
  case "$1" in 0) printf 'auto' ;; 1) printf 'fan' ;; 2) printf 'grid' ;; 3) printf 'list' ;; *) printf '' ;; esac
}
name_to_view() {
  case "$1" in auto) printf '0' ;; fan) printf '1' ;; grid) printf '2' ;; list) printf '3' ;; *) printf '' ;; esac
}

sort_to_name() {
  case "$1" in
    1) printf 'name' ;;
    2) printf 'date-added' ;;
    3) printf 'date-modified' ;;
    4) printf 'date-created' ;;
    5) printf 'kind' ;;
    *) printf '' ;;
  esac
}
name_to_sort() {
  case "$1" in
    name) printf '1' ;;
    date-added) printf '2' ;;
    date-modified) printf '3' ;;
    date-created) printf '4' ;;
    kind) printf '5' ;;
    *) printf '' ;;
  esac
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

# A tile stores its target as a file URL, so a space arrives as `%20`. `printf
# %b` turns the escapes back into bytes, which keeps a non-ASCII application
# name intact because each byte of its UTF-8 sequence is escaped separately.
# A literal backslash is doubled first, so a path may contain one.
url_to_path() {
  local url="$1"

  url="${url#file://}"
  url="${url%/}"
  url="${url//\\/\\\\}"

  printf '%b' "${url//%/\\x}"
}

# The home directory carries the account name, and this repository is public.
home_to_tilde() {
  local path="$1"

  if [[ "$path" == "$HOME" || "$path" == "$HOME/"* ]]; then
    printf '~%s' "${path#"$HOME"}"
  else
    printf '%s' "$path"
  fi
}

tilde_to_home() {
  local path="$1"

  if [[ "$path" == "~" || "$path" == "~/"* ]]; then
    printf '%s%s' "$HOME" "${path#\~}"
  else
    printf '%s' "$path"
  fi
}

# `plutil -extract` prints the element count for an array, and fails when the
# key is absent, which is what an empty Dock section looks like.
tile_count() {
  local key="$1" count

  count="$(plutil -extract "$key" raw -o - "$TEMPORARY_PLIST" 2>/dev/null)" || count=0

  if [[ ! "$count" =~ ^[0-9]+$ ]]; then
    count=0
  fi

  printf '%s' "$count"
}

tile_field() {
  local key_path="$1"

  plutil -extract "$key_path" raw -o - "$TEMPORARY_PLIST" 2>/dev/null || printf ''
}

tile_path() {
  local key_path="$1" url

  url="$(tile_field "$key_path")"

  if [[ -z "$url" ]]; then
    printf ''
    return 0
  fi

  home_to_tilde "$(url_to_path "$url")"
}

# `defaults export` asks cfprefsd for the domain, so it sees a Dock that was
# rearranged seconds ago and has not been flushed to disk yet. Reading the
# preference file directly would not.
read_dock_domain() {
  TEMPORARY_PLIST="$(mktemp)"

  if ! defaults export "$DOCK_DOMAIN" - >"$TEMPORARY_PLIST"; then
    printf 'Could not read the %s preference domain.\n' "$DOCK_DOMAIN" >&2
    exit 1
  fi
}

manifest_header() {
  cat <<'HEADER'
# The managed Dock, in Dock order from left to right.
#
#   mise run dock:apply    rebuild the Dock from this file
#   mise run dock:export   capture the running Dock into this file
#
# `mise run dock:apply --dry-run` prints the Dock it would build, tile by tile,
# and changes nothing.
#
# An `app` line is an application bundle. `mise run dock:apply` skips one that
# is not installed and reports it, so a Mac that is still missing an app gets
# the rest of the Dock in the right order. Running the task again after the
# application arrives puts it back in its place.
#
# A `folder` line is a stack, and its options are the ones in the Dock context
# menu: display=stack|folder, view=auto|fan|grid|list, and
# sort=name|date-added|date-modified|date-created|kind.
#
# `~` is the home directory, so this file carries no account name.
HEADER
}

export_dock() {
  local output="" index count tile_type path
  local display view sort

  read_dock_domain

  count="$(tile_count "$APPS_KEY")"

  if [[ "$count" -eq 0 ]]; then
    # A Mac that has not been set up yet still has a Dock, and it is macOS's
    # own. Overwriting the manifest from an empty one is the single way this
    # task can destroy work, so it refuses instead.
    printf 'The Dock reports no applications, so there is nothing to capture.\n' >&2
    printf 'Run `mise run dock:apply` to restore the managed Dock instead.\n' >&2
    exit 1
  fi

  output+="$(manifest_header)"
  output+=$'\n\n'

  for ((index = 0; index < count; index++)); do
    tile_type="$(tile_field "${APPS_KEY}.${index}.tile-type")"
    path="$(tile_path "${APPS_KEY}.${index}.tile-data.file-data._CFURLString")"

    if [[ "$tile_type" != "file-tile" || -z "$path" ]]; then
      printf 'Skipped an unsupported application tile at position %s (%s).\n' \
        "$index" "${tile_type:-unknown}" >&2
      continue
    fi

    output+="app	${path}"$'\n'
  done

  count="$(tile_count "$OTHERS_KEY")"

  for ((index = 0; index < count; index++)); do
    tile_type="$(tile_field "${OTHERS_KEY}.${index}.tile-type")"
    path="$(tile_path "${OTHERS_KEY}.${index}.tile-data.file-data._CFURLString")"

    if [[ "$tile_type" != "directory-tile" || -z "$path" ]]; then
      # A recent-items tile, a dropped file, a URL, and a spacer all live in
      # this array. None of them is expressible as a path plus a view, so the
      # manifest says so out loud rather than quietly claiming to hold the
      # whole Dock.
      printf 'Skipped an unsupported tile at position %s (%s).\n' \
        "$index" "${tile_type:-unknown}" >&2
      continue
    fi

    display="$(display_to_name "$(tile_field "${OTHERS_KEY}.${index}.tile-data.displayas")")"
    view="$(view_to_name "$(tile_field "${OTHERS_KEY}.${index}.tile-data.showas")")"
    sort="$(sort_to_name "$(tile_field "${OTHERS_KEY}.${index}.tile-data.arrangement")")"

    output+="folder	display=${display:-stack}	view=${view:-auto}	sort=${sort:-name}	${path}"$'\n'
  done

  if [[ "$PRINT_ONLY" == true ]]; then
    printf '%s' "$output"
    return 0
  fi

  printf '%s' "$output" >"$MANIFEST"

  log "Captured the Dock into dock.txt"
  printf '\nReview the change with `git diff dock.txt` and commit it.\n'
}

json_string() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"

  printf '"%s"' "$value"
}

# A tile is written as a path rather than a file URL, which is what
# `_CFURLStringType` 0 means. The Dock resolves it on the next restart and
# writes back its own URL, bookmark, and label, so nothing here has to encode a
# space or invent a GUID.
app_tile_json() {
  printf '{"tile-type":"file-tile","tile-data":{"file-data":{"_CFURLString":%s,"_CFURLStringType":0}}}' \
    "$(json_string "$1")"
}

folder_tile_json() {
  printf '{"tile-type":"directory-tile","tile-data":{"file-data":{"_CFURLString":%s,"_CFURLStringType":0},"file-type":2,"displayas":%s,"showas":%s,"arrangement":%s}}' \
    "$(json_string "$1")" "$2" "$3" "$4"
}

# `defaults write` takes a whole plist for one key, so the two arrays are
# replaced in place. Importing an edited copy of the domain instead would carry
# every unrelated Dock key back with it, including the ones mise owns.
write_tiles() {
  local key="$1" tiles="$2" count="$3" plist

  if ! plist="$(printf '[%s]' "$tiles" | plutil -convert xml1 -o - - 2>/dev/null)"; then
    printf 'Could not build the %s value for the Dock.\n' "$key" >&2
    exit 1
  fi

  # The generated plist is a few hundred lines of XML. A dry run that printed
  # it would bury the layout it is supposed to be showing, and the layout is
  # already listed above, tile by tile.
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + defaults write %s %s, %s tile(s)\n' "$DOCK_DOMAIN" "$key" "$count"
    return 0
  fi

  defaults write "$DOCK_DOMAIN" "$key" "$plist"
}

restart_dock() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '  + killall Dock\n'
    return 0
  fi

  # The Dock reads these arrays once at launch, so the layout only appears
  # after it restarts. `killall` fails when it is not running, which is not a
  # failure of this task.
  killall Dock 2>/dev/null || true
}

apply_dock() {
  local line kind rest token key value path resolved
  local display view sort
  local app_tiles="" folder_tiles=""
  local -a missing=() planned=()
  local app_count=0 folder_count=0 app_lines=0
  local line_number=0

  if [[ ! -r "$MANIFEST" ]]; then
    printf 'The Dock manifest is missing at %s.\n' "$MANIFEST" >&2
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    line="$(trim "$line")"

    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi

    kind="${line%%[[:space:]]*}"
    rest="$(trim "${line#"$kind"}")"

    case "$kind" in
      app)
        app_lines=$((app_lines + 1))
        resolved="$(tilde_to_home "$rest")"

        # A Mac that is still installing its applications is the normal case
        # here, not an error. The tile is left out and reported, and the next
        # run of this task inserts it at its manifest position.
        if [[ ! -e "$resolved" ]]; then
          missing+=("$rest")
          continue
        fi

        app_tiles+="${app_tiles:+,}$(app_tile_json "$resolved")"
        app_count=$((app_count + 1))
        planned+=("$rest")
        ;;
      folder)
        display=stack
        view=auto
        sort=name

        while [[ "$rest" == *=* ]]; do
          token="${rest%%[[:space:]]*}"
          key="${token%%=*}"
          value="${token#*=}"

          case "$key" in
            display) display="$value" ;;
            view) view="$value" ;;
            sort) sort="$value" ;;
            *) break ;;
          esac

          rest="$(trim "${rest#"$token"}")"
        done

        path="$rest"
        resolved="$(tilde_to_home "$path")"

        if [[ -z "$(name_to_display "$display")" ||
          -z "$(name_to_view "$view")" ||
          -z "$(name_to_sort "$sort")" ]]; then
          printf '%s line %s: unknown stack option.\n' "$MANIFEST" "$line_number" >&2
          exit 1
        fi

        if [[ ! -e "$resolved" ]]; then
          missing+=("$path")
          continue
        fi

        folder_tiles+="${folder_tiles:+,}$(folder_tile_json \
          "$resolved" \
          "$(name_to_display "$display")" \
          "$(name_to_view "$view")" \
          "$(name_to_sort "$sort")")"
        folder_count=$((folder_count + 1))
        planned+=("$path as a $display, $view view, sorted by $sort")
        ;;
      *)
        printf '%s line %s: expected `app` or `folder`, found `%s`.\n' \
          "$MANIFEST" "$line_number" "$kind" >&2
        exit 1
        ;;
    esac
  done <"$MANIFEST"

  if [[ "$app_lines" -eq 0 ]]; then
    printf '%s lists no application, so there is no Dock to build.\n' "$MANIFEST" >&2
    exit 1
  fi

  # Applying an all-empty Dock is never what someone meant by this task, and a
  # Mac that has installed nothing yet would otherwise end up with one.
  if [[ -z "$app_tiles" ]]; then
    printf 'No application in dock.txt is installed, so the Dock is left alone.\n' >&2
    exit 1
  fi

  log "Applying the managed Dock"

  if [[ "$DRY_RUN" == true ]]; then
    printf '\nThe Dock would hold, from left to right:\n'
    printf '  %s\n' "${planned[@]}"
    printf '\n'
  fi

  write_tiles "$APPS_KEY" "$app_tiles" "$app_count"
  write_tiles "$OTHERS_KEY" "$folder_tiles" "$folder_count"
  restart_dock

  if [[ ${#missing[@]} -gt 0 ]]; then
    printf '\nLeft out, because they are not installed yet:\n'
    printf '  %s\n' "${missing[@]}"
    printf '\nRun `mise run dock:apply` again once they are, and each one returns\n'
    printf 'to its place in dock.txt.\n'
  else
    printf '\nThe Dock matches dock.txt.\n'
  fi
}

case "$COMMAND" in
  apply)
    apply_dock
    ;;
  export)
    export_dock
    ;;
esac
