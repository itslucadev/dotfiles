#!/usr/bin/env bash

set -Eeuo pipefail

readonly RAYCAST_PAGE_URL="https://www.raycast.com/new"
readonly APPLICATION_PATH="/Applications/Raycast Beta.app"
readonly EXPECTED_BUNDLE_ID="com.raycast-x.macos"
readonly EXPECTED_TEAM_ID="SY64MV22J9"

verify_application() {
  local application_path="$1"
  local bundle_id
  local team_id

  bundle_id="$(
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
      "$application_path/Contents/Info.plist"
  )"
  if [[ "$bundle_id" != "$EXPECTED_BUNDLE_ID" ]]; then
    printf 'Unexpected Raycast Beta bundle identifier: %s\n' "$bundle_id" >&2
    return 1
  fi

  team_id="$(
    codesign -dv --verbose=4 "$application_path" 2>&1 |
      awk -F= '/^TeamIdentifier=/{print $2; exit}'
  )"
  if [[ "$team_id" != "$EXPECTED_TEAM_ID" ]]; then
    printf 'Unexpected Raycast Beta signing team: %s\n' "${team_id:-missing}" >&2
    return 1
  fi

  codesign --verify --deep --strict "$application_path"
  spctl --assess --type execute "$application_path"
}

if [[ "${1:-}" == "--dry-run" ]]; then
  printf 'Would download and verify Raycast v2 Beta from %s.\n' "$RAYCAST_PAGE_URL"
  exit 0
elif [[ "$#" -gt 0 ]]; then
  printf 'Usage: %s [--dry-run]\n' "${0##*/}" >&2
  exit 64
fi

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  printf 'Raycast v2 Beta requires an Apple Silicon Mac.\n'
  exit 0
fi

readonly macos_major="$(sw_vers -productVersion | cut -d. -f1)"
if (( macos_major < 26 )); then
  printf 'Raycast v2 Beta requires macOS Tahoe or newer and was skipped.\n'
  exit 0
fi

if [[ -d "$APPLICATION_PATH" ]]; then
  if verify_application "$APPLICATION_PATH" >/dev/null 2>&1; then
    printf 'Raycast v2 Beta is already installed and will update itself.\n'
    exit 0
  fi

  printf 'Raycast Beta exists but its signature is invalid.\n' >&2
  printf 'Remove it manually after inspection, then rerun this script.\n' >&2
  exit 1
fi

readonly page_html="$(curl -fsSL "$RAYCAST_PAGE_URL")"
readonly download_url="$(
  printf '%s' "$page_html" |
    grep -Eo 'https://x-r2\.raycast-releases\.com/[^"< ]+_arm64\.dmg' |
    head -n 1
)"

if [[ -z "$download_url" ]]; then
  printf 'Could not discover the official Raycast Beta download URL.\n' >&2
  exit 1
fi

readonly temporary_directory="$(mktemp -d)"
readonly disk_image="$temporary_directory/Raycast-Beta.dmg"
readonly mount_point="$temporary_directory/mount"

cleanup() {
  if mount | grep -Fq "on $mount_point "; then
    hdiutil detach "$mount_point" -quiet || true
  fi
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

mkdir "$mount_point"
curl -fL "$download_url" -o "$disk_image"
hdiutil attach "$disk_image" -nobrowse -readonly -mountpoint "$mount_point" -quiet

readonly source_application="$mount_point/Raycast Beta.app"
if [[ ! -d "$source_application" ]]; then
  printf 'The downloaded disk image does not contain Raycast Beta.app.\n' >&2
  exit 1
fi

verify_application "$source_application"

sudo ditto "$source_application" "$APPLICATION_PATH"
verify_application "$APPLICATION_PATH"

printf 'Raycast v2 Beta was installed from the official signed disk image.\n'
