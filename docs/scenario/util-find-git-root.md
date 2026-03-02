# Scenario: find_git_root Function

- Given: A buffer file path (absolute or relative)
- When: The function is called with this path
- Then: Returns the first parent directory containing `.git`, or nil if not found

## Test Steps

- Case 1 (happy path): Path inside a git repo - returns the git root
- Case 2 (nested git): Path inside nested git repos - returns the nearest git root (closest parent)
- Case 3 (no git): Path not in any git repo - returns nil
- Case 4 (git worktree): Path in a git worktree where `.git` is a file - returns the worktree root
- Case 5 (root directory): Already at git root - returns the same directory
- Case 6 (nil/empty path): Invalid input - returns nil

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor