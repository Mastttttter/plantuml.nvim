# Scenario: Shutdown Notification Endpoint

- Given: Server is running with SSE clients connected
- When: POST /shutdown endpoint is called
- Then: Server broadcasts "shutdown" event to all connected clients

## Test Steps

- Case 1 (broadcast shutdown): All connected SSE clients receive "shutdown" event
- Case 2 (no clients): Endpoint returns 200 OK even when no clients are connected
- Case 3 (response): Returns 200 OK with success message

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor