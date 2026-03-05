# Scenario: notify_shutdown function

- Given: An HTTP client module with notify_shutdown function
- When: notify_shutdown is called with valid host, port, and callback
- Then: HTTP POST request is sent to the server's /shutdown endpoint

## Test Steps

- Case 1 (happy path): Call notify_shutdown with valid parameters, verify curl command is executed with correct URL
- Case 2 (connection error): Call notify_shutdown with unreachable host/port, verify vim.notify is called with ERROR level and callback receives (false, error)
- Case 3 (callback verification): Verify callback is called after request completes

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor