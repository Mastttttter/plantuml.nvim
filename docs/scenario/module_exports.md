# Scenario: Module exports and vim.system usage

- Given: An HTTP client module
- When: Module is loaded
- Then: Module exports notify_update and notify_shutdown functions, uses vim.system when available

## Test Steps

- Case 1 (exports): Verify module exports notify_update function
- Case 2 (exports): Verify module exports notify_shutdown function
- Case 3 (vim.system usage): Verify vim.system is called with correct arguments

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor