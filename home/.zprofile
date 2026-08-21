# Homebrew is installed in the standard Apple Silicon prefix.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
#
# Coding agents inherit SSH_AUTH_SOCK and ask ssh-agent to sign. They never
# read the passphrase-protected key. The socket is created by
# scripts/setup-ssh-agent.sh at a stable path so SSH logins and GUI terminals
# share the same agent. Aqua's launchd socket is not exported into sshd
# sessions, which is why this cannot use `launchctl getenv SSH_AUTH_SOCK`.
if [[ -S "$HOME/.ssh/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
