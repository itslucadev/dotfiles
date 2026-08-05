#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly GITHUB_HOST="github.com"
readonly SSH_DIRECTORY="$HOME/.ssh"
readonly PRIVATE_KEY="$SSH_DIRECTORY/id_ed25519"
readonly PUBLIC_KEY="$PRIVATE_KEY.pub"
readonly ALLOWED_SIGNERS="$SSH_DIRECTORY/allowed_signers"
readonly GITHUB_SCOPES="admin:public_key,admin:ssh_signing_key"
readonly MANUAL_ACTION_EXIT=2

DRY_RUN=false
STATUS_ONLY=false
PRIVATE_KEY_REQUIRES_PASSPHRASE=false
TEMPORARY_PRIVATE_KEY=""
TEMPORARY_PUBLIC_KEY=""
TEMPORARY_SSH_OUTPUT=""

cleanup() {
  if [[ -n "$TEMPORARY_PRIVATE_KEY" ]]; then
    rm -f "$TEMPORARY_PRIVATE_KEY"
  fi

  if [[ -n "$TEMPORARY_PUBLIC_KEY" ]]; then
    rm -f "$TEMPORARY_PUBLIC_KEY"
  fi

  if [[ -n "$TEMPORARY_SSH_OUTPUT" ]]; then
    rm -f "$TEMPORARY_SSH_OUTPUT"
  fi
}

trap cleanup EXIT

usage() {
  printf 'Usage: %s [--dry-run | --status]\n' "${0##*/}"
}

for argument in "$@"; do
  case "$argument" in
    --dry-run)
      DRY_RUN=true
      ;;
    --status)
      STATUS_ONLY=true
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

if [[ "$DRY_RUN" == true && "$STATUS_ONLY" == true ]]; then
  usage >&2
  exit 64
fi

# The Git identity is configured by hand and is no longer part of this
# repository, so the key comment and the allowed signers entry come from the
# identity that is actually in effect on this machine.
readonly GITHUB_EMAIL="$(git config --global --get user.email || true)"

if [[ -z "$GITHUB_EMAIL" ]]; then
  printf 'Git has no global user.email, so the SSH key cannot be labelled.\n' >&2
  printf 'Configure the Git identity first, then rerun this script:\n' >&2
  printf '  git config --global user.name "your-github-username"\n' >&2
  printf '  git config --global user.email "your-github-noreply-address"\n' >&2
  exit "$MANUAL_ACTION_EXIT"
fi

print_command() {
  local argument=""

  printf '  +'
  for argument in "$@"; do
    printf ' %q' "$argument"
  done
  printf '\n'
}

key_title() {
  local computer_name=""

  computer_name="$(scutil --get ComputerName 2>/dev/null || true)"
  printf '%s\n' "${computer_name:-Mac}"
}

public_key_value() {
  awk 'NR == 1 { print $1 " " $2 }' "$PUBLIC_KEY"
}

public_key_blob() {
  awk 'NR == 1 { print $2 }' "$PUBLIC_KEY"
}

expected_signer() {
  printf '%s %s\n' "$GITHUB_EMAIL" "$(public_key_value)"
}

key_pair_matches() {
  local private_fingerprint=""
  local public_fingerprint=""

  TEMPORARY_PRIVATE_KEY="$(
    mktemp "${SSH_DIRECTORY}/private-key-check.XXXXXX"
  )"
  chmod 600 "$TEMPORARY_PRIVATE_KEY"
  cp "$PRIVATE_KEY" "$TEMPORARY_PRIVATE_KEY"

  private_fingerprint="$(
    ssh-keygen -lf "$TEMPORARY_PRIVATE_KEY" 2>/dev/null |
      awk 'NR == 1 { print $2 }'
  )"
  public_fingerprint="$(
    ssh-keygen -lf "$PUBLIC_KEY" 2>/dev/null |
      awk 'NR == 1 { print $2 }'
  )"

  rm -f "$TEMPORARY_PRIVATE_KEY"
  TEMPORARY_PRIVATE_KEY=""

  [[ -n "$private_fingerprint" &&
    "$private_fingerprint" == "$public_fingerprint" ]]
}

remote_has_key() {
  local endpoint="$1"
  local registered_keys=""

  if ! registered_keys="$(
    gh api --paginate "$endpoint" --jq '.[].key' 2>&1
  )"; then
    printf '%s\n' "$registered_keys" >&2
    return 2
  fi

  awk '
    NF == 1 { print $1 }
    NF >= 2 { print $2 }
  ' <<<"$registered_keys" |
    grep -Fxq "$(public_key_blob)"
}

github_scopes_are_available() {
  local auth_status=""

  if ! auth_status="$(
    gh auth status --active --hostname "$GITHUB_HOST" 2>&1
  )"; then
    return 1
  fi

  grep -Fq 'admin:public_key' <<<"$auth_status" &&
    grep -Fq 'admin:ssh_signing_key' <<<"$auth_status"
}

manual_action_required() {
  printf 'Manual action required.\n' >&2
  printf '%s\n' "$1" >&2

  if [[ ! -t 0 ]]; then
    printf 'Then run: mise run github:ssh\n' >&2
    printf 'To continue the complete setup afterward, run: ./bootstrap.sh\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi

  printf 'Press Return after completing the action. The setup will retry and verify it.\n'
  if ! read -r; then
    printf 'Interactive input ended before the action was confirmed.\n' >&2
    exit "$MANUAL_ACTION_EXIT"
  fi
}

ensure_github_login() {
  if ! command -v gh >/dev/null 2>&1; then
    printf 'GitHub CLI is required but was not found.\n' >&2
    exit 1
  fi

  if gh auth status --active --hostname "$GITHUB_HOST" >/dev/null 2>&1; then
    return
  fi

  if [[ ! -t 0 ]]; then
    manual_action_required \
      "Run: gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --scopes $GITHUB_SCOPES"
  fi

  until gh auth status --active --hostname "$GITHUB_HOST" >/dev/null 2>&1; do
    printf 'GitHub login is required before setup can continue.\n'
    if gh auth login \
      --hostname "$GITHUB_HOST" \
      --git-protocol ssh \
      --web \
      --skip-ssh-key \
      --scopes "$GITHUB_SCOPES" &&
      gh auth status --active --hostname "$GITHUB_HOST" >/dev/null 2>&1; then
      break
    fi

    manual_action_required \
      "Complete the GitHub CLI login with scopes: $GITHUB_SCOPES"
  done
}

refresh_github_scopes() {
  if [[ ! -t 0 ]]; then
    manual_action_required \
      "Run: gh auth refresh --hostname github.com --scopes $GITHUB_SCOPES"
  fi

  until gh auth refresh \
    --hostname "$GITHUB_HOST" \
    --scopes "$GITHUB_SCOPES"; do
    manual_action_required \
      "Refresh the GitHub CLI scopes: $GITHUB_SCOPES"
  done
}

ensure_github_scopes() {
  while ! github_scopes_are_available; do
    refresh_github_scopes

    if ! github_scopes_are_available; then
      manual_action_required \
        "Confirm that GitHub CLI has both required scopes: $GITHUB_SCOPES"
    fi
  done
}

test_github_connection() {
  while true; do
    TEMPORARY_SSH_OUTPUT="$(mktemp)"

    printf 'Testing the GitHub SSH connection.\n'
    printf 'On the first connection, compare the shown fingerprint with GitHub documentation.\n'
    if ssh -T git@github.com 2>&1 | tee "$TEMPORARY_SSH_OUTPUT"; then
      :
    fi

    if grep -Fq 'successfully authenticated' "$TEMPORARY_SSH_OUTPUT"; then
      rm -f "$TEMPORARY_SSH_OUTPUT"
      TEMPORARY_SSH_OUTPUT=""
      printf 'GitHub SSH authentication succeeded.\n'
      return
    fi

    if grep -Fq 'Host key verification failed' "$TEMPORARY_SSH_OUTPUT"; then
      rm -f "$TEMPORARY_SSH_OUTPUT"
      TEMPORARY_SSH_OUTPUT=""
      manual_action_required \
        "Verify GitHub's published SSH host fingerprint and accept it when prompted."
      continue
    fi

    printf 'GitHub SSH authentication test failed.\n' >&2
    printf 'Resolve the SSH error above, then rerun: mise run github:ssh\n' >&2
    exit 1
  done
}

local_status() {
  local expected=""

  if [[ ! -f "$PRIVATE_KEY" || ! -f "$PUBLIC_KEY" ]]; then
    printf 'Missing SSH key pair at %s.\n' "$PRIVATE_KEY" >&2
    return 1
  fi

  if ! ssh-keygen -lf "$PUBLIC_KEY" >/dev/null 2>&1; then
    printf 'Invalid SSH public key: %s\n' "$PUBLIC_KEY" >&2
    return 1
  fi

  if ! key_pair_matches; then
    printf 'SSH private and public keys do not match.\n' >&2
    return 1
  fi

  expected="$(expected_signer)"
  if [[ ! -f "$ALLOWED_SIGNERS" ]] ||
    ! grep -Fxq "$expected" "$ALLOWED_SIGNERS"; then
    printf 'The managed identity is missing from %s.\n' "$ALLOWED_SIGNERS" >&2
    return 1
  fi

  printf 'GitHub SSH key is configured locally.\n'
}

remote_status() {
  if ! command -v gh >/dev/null 2>&1 ||
    ! gh auth status --active --hostname "$GITHUB_HOST" >/dev/null 2>&1; then
    printf 'GitHub CLI is not authenticated for %s.\n' "$GITHUB_HOST" >&2
    return 1
  fi

  if ! remote_has_key user/keys; then
    printf 'SSH authentication key is not registered with GitHub.\n' >&2
    return 1
  fi

  if ! remote_has_key user/ssh_signing_keys; then
    printf 'SSH signing key is not registered with GitHub.\n' >&2
    return 1
  fi

  printf 'GitHub SSH key is registered for authentication and signing.\n'
}

if [[ "$STATUS_ONLY" == true ]]; then
  local_status
  remote_status
  exit 0
fi

printf 'Configuring one Ed25519 key for GitHub authentication and signing\n'

if [[ "$DRY_RUN" == true ]]; then
  print_command mkdir -p "$SSH_DIRECTORY"
  print_command chmod 700 "$SSH_DIRECTORY"
  print_command ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$PRIVATE_KEY"
  print_command chmod 600 "$PRIVATE_KEY"
  print_command chmod 644 "$PUBLIC_KEY"
  print_command ssh-add --apple-use-keychain "$PRIVATE_KEY"
  printf '  + update %q for %q\n' "$ALLOWED_SIGNERS" "$GITHUB_EMAIL"
  print_command gh auth login \
    --hostname "$GITHUB_HOST" \
    --git-protocol ssh \
    --web \
    --skip-ssh-key \
    --scopes "$GITHUB_SCOPES"
  print_command gh auth refresh \
    --hostname "$GITHUB_HOST" \
    --scopes "$GITHUB_SCOPES"
  print_command gh ssh-key add "$PUBLIC_KEY" \
    --type authentication \
    --title "Mac"
  print_command gh ssh-key add "$PUBLIC_KEY" \
    --type signing \
    --title "Mac"
  print_command ssh -T git@github.com
  exit 0
fi

mkdir -p "$SSH_DIRECTORY"
chmod 700 "$SSH_DIRECTORY"

if [[ -e "$PRIVATE_KEY" && ! -f "$PRIVATE_KEY" ]]; then
  printf 'SSH private key path is not a regular file: %s\n' "$PRIVATE_KEY" >&2
  exit 1
fi

if [[ -e "$PUBLIC_KEY" && ! -f "$PUBLIC_KEY" ]]; then
  printf 'SSH public key path is not a regular file: %s\n' "$PUBLIC_KEY" >&2
  exit 1
fi

if [[ ! -f "$PRIVATE_KEY" && -f "$PUBLIC_KEY" ]]; then
  printf 'Refusing to replace an orphaned public key: %s\n' "$PUBLIC_KEY" >&2
  exit 1
fi

if [[ ! -f "$PRIVATE_KEY" ]]; then
  if [[ ! -t 0 ]]; then
    manual_action_required \
      "An interactive terminal is required to choose the SSH key passphrase."
  fi

  ssh-keygen -t ed25519 -C "$GITHUB_EMAIL" -f "$PRIVATE_KEY"
fi

if ! ssh-keygen -y -P "" -f "$PRIVATE_KEY" >/dev/null 2>&1; then
  PRIVATE_KEY_REQUIRES_PASSPHRASE=true
fi

if [[ ! -f "$PUBLIC_KEY" ]]; then
  if [[ "$PRIVATE_KEY_REQUIRES_PASSPHRASE" == true && ! -t 0 ]]; then
    manual_action_required \
      "An interactive terminal is required to unlock the existing SSH private key and reconstruct its public key."
  fi

  TEMPORARY_PUBLIC_KEY="$(mktemp "${SSH_DIRECTORY}/id_ed25519.pub.XXXXXX")"
  ssh-keygen -y -f "$PRIVATE_KEY" >"$TEMPORARY_PUBLIC_KEY"
  chmod 644 "$TEMPORARY_PUBLIC_KEY"
  mv "$TEMPORARY_PUBLIC_KEY" "$PUBLIC_KEY"
  TEMPORARY_PUBLIC_KEY=""
fi

chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

if ! ssh-keygen -lf "$PUBLIC_KEY" >/dev/null 2>&1; then
  printf 'Invalid SSH public key: %s\n' "$PUBLIC_KEY" >&2
  exit 1
fi

if [[ "$(awk 'NR == 1 { print $1 }' "$PUBLIC_KEY")" != "ssh-ed25519" ]]; then
  printf 'Expected an Ed25519 public key at %s.\n' "$PUBLIC_KEY" >&2
  exit 1
fi

if ! key_pair_matches; then
  printf 'Refusing to use a mismatched SSH key pair:\n' >&2
  printf '  %s\n' "$PRIVATE_KEY" >&2
  printf '  %s\n' "$PUBLIC_KEY" >&2
  exit 1
fi

fingerprint="$(ssh-keygen -lf "$PUBLIC_KEY" | awk 'NR == 1 { print $2 }')"
if ! ssh-add -l 2>/dev/null | grep -Fq "$fingerprint"; then
  if [[ "$PRIVATE_KEY_REQUIRES_PASSPHRASE" == true ]]; then
    if [[ ! -t 0 ]]; then
      manual_action_required \
        "An interactive terminal is required to unlock the existing SSH private key."
    fi

    ssh-add --apple-use-keychain "$PRIVATE_KEY"
  else
    ssh-add "$PRIVATE_KEY"
  fi
fi

expected="$(expected_signer)"
if [[ ! -f "$ALLOWED_SIGNERS" ]]; then
  printf '%s\n' "$expected" >"$ALLOWED_SIGNERS"
elif ! grep -Fxq "$expected" "$ALLOWED_SIGNERS"; then
  if [[ -s "$ALLOWED_SIGNERS" &&
    -n "$(tail -c 1 "$ALLOWED_SIGNERS")" ]]; then
    printf '\n' >>"$ALLOWED_SIGNERS"
  fi
  printf '%s\n' "$expected" >>"$ALLOWED_SIGNERS"
fi
chmod 644 "$ALLOWED_SIGNERS"

printf 'GitHub SSH key is configured locally.\n'

ensure_github_login
ensure_github_scopes

if remote_has_key user/keys; then
  printf 'GitHub authentication key is already registered.\n'
else
  remote_result=$?
  if [[ "$remote_result" -eq 2 ]]; then
    printf 'Could not inspect GitHub authentication keys.\n' >&2
    exit 1
  elif ! gh ssh-key add "$PUBLIC_KEY" \
      --type authentication \
      --title "$(key_title)"; then
    printf 'Could not upload the GitHub authentication key.\n' >&2
    exit 1
  fi
fi

if remote_has_key user/ssh_signing_keys; then
  printf 'GitHub signing key is already registered.\n'
else
  remote_result=$?
  if [[ "$remote_result" -eq 2 ]]; then
    printf 'Could not inspect GitHub signing keys.\n' >&2
    exit 1
  elif ! gh ssh-key add "$PUBLIC_KEY" \
      --type signing \
      --title "$(key_title)"; then
    printf 'Could not upload the GitHub signing key.\n' >&2
    exit 1
  fi
fi

if remote_status; then
  test_github_connection
else
  printf 'GitHub key registration is incomplete.\n' >&2
  exit 1
fi
