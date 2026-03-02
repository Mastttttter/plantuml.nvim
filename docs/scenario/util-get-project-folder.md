# Scenario: get_project_folder Function

- Given: A buffer file path
- When: The function is called with this path
- Then: Returns the git root if found, otherwise returns the current working directory

## Test Steps

- Case 1 (happy path): Path inside a git repo - returns git root
- Case 2 (no git): Path not in git repo - returns cwd fallback
- Case 3 (nil path): Nil input - returns cwd
- Case 4 (empty string): Empty string input - returns cwd

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor