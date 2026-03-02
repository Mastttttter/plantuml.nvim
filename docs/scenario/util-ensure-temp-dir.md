# Scenario: ensure_temp_dir Function

- Given: The function is called
- When: The temp directory `/tmp/plantuml.nvim/` may or may not exist
- Then: Creates the directory if needed and returns the path, or nil on failure

## Test Steps

- Case 1 (happy path - create): Directory doesn't exist - creates it with proper permissions
- Case 2 (already exists): Directory already exists - returns the path without error
- Case 3 (idempotent): Calling twice in a row - both succeed, no errors
- Case 4 (permissions): Created directory has proper permissions (rwx for owner)

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor