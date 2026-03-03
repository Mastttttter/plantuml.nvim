# Scenario: Server URL Callback

- Given: The server starts successfully
- When: The server is ready to accept connections
- Then: The callback function is called with the full server URL

## Test Steps

- Case 1 (happy path): Callback receives "http://localhost:<port>" URL
- Case 2 (default port): With port 8912, callback receives "http://localhost:8912"
- Case 3 (custom port): With custom port, callback receives correct URL
- Case 4 (fallback port): After port conflict, callback receives URL with new port
- Case 5 (nil callback): Module handles nil callback gracefully

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor
