# Scenario: notify_update function

- Given: An HTTP client module with notify_update function
- When: notify_update is called with valid host, port, filename, filepath, and callback
- Then: HTTP POST request is sent to the server with JSON body

## Test Steps

- Case 1 (happy path): Call notify_update with valid parameters, verify curl command is executed with correct URL and JSON body
- Case 2 (connection error): Call notify_update with unreachable host/port, verify vim.notify is called with ERROR level and callback receives (false, error)
- Case 3 (callback verification): Verify callback is called after request completes

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor