# Mac Setup Implementation Plan

## Scope

Implement the approved public macOS setup without applying it to the current Mac.

## Tasks

1. Create the Homebrew formula, cask, font, and Mac App Store inventories.
2. Configure mise runtimes, Bun-backed npm CLIs, environment variables, tasks, lockfiles, dotfiles, and macOS defaults.
3. Create idempotent bootstrap and reapply entry points.
4. Create safe installers for Raycast v2 Beta and Mac App Store applications.
5. Create the native shortcut reservation script.
6. Create a read-only doctor and repository test suite.
7. Document automatic behavior, manual permissions, authentication, React Native setup, and the new-Mac acceptance test.
8. Validate every configuration without executing the real setup.
9. Commit the implementation on the feature branch.
10. Integrate the verified branch and prepare the GitHub remote.
