# Scenario: Server Lifecycle Management in Lua

- Given: The lua/plantuml/server.lua module is loaded
- When: start_server(callback) is called
- Then: Node.js server process is spawned and tracked, callback receives the URL

## Test Steps

- Case 1 (happy path): start_server spawns process and calls callback with URL
- Case 2 (stop server): stop_server kills the tracked process
- Case 3 (server already running): Calling start_server when server is running returns existing URL
- Case 4 (no node.js): start_server notifies error when node is not available
- Case 5 (process tracking): Server handle is stored for lifecycle management

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor