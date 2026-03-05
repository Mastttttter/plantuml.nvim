# Scenario: SSE Events Endpoint

- Given: Server is running with SSE support
- When: Client connects to GET /events endpoint
- Then: Server maintains SSE connection and can broadcast update and shutdown events

## Test Steps

- Case 1 (SSE headers): Connection returns Content-Type: text/event-stream, Cache-Control: no-cache, Connection: keep-alive
- Case 2 (initial message): Client receives initial connection message
- Case 3 (client tracking): Server tracks connected clients in a Set
- Case 4 (update event): Server can broadcast "update" event to all clients
- Case 5 (shutdown event): Server can broadcast "shutdown" event to all clients
- Case 6 (disconnect cleanup): Client disconnect removes client from tracking Set

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor