# Scenario: HTTP error handling

- Given: An HTTP client module with error handling
- When: HTTP request fails due to network error, timeout, or non-2xx response
- Then: Error is reported via vim.notify with ERROR level and callback receives (false, error_message)

## Test Steps

- Case 1 (connection refused): Simulate curl failing with exit code 7, verify error handling
- Case 2 (timeout): Simulate curl timeout, verify error handling
- Case 3 (non-2xx response): Simulate 404 or 500 response, verify error handling

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor