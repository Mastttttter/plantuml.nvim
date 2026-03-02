# Scenario: Port Conflict Detection with Fallback

- Given: A port is already in use
- When: start_server is called with that port
- Then: Server automatically tries the next port until it finds an available one

## Test Steps

- Case 1 (happy path): Server starts on configured port when available
- Case 2 (port conflict): Server increments port when configured port is busy
- Case 3 (multiple conflicts): Server continues incrementing through multiple busy ports
- Case 4 (port range limit): Server notifies error when all ports in range are busy
- Case 5 (fallback success): Callback receives the actual port used, not the configured one

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor