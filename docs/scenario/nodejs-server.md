# Scenario: Node.js Static File Server

- Given: The server/server.js file exists
- When: Node.js executes the server script with a port argument
- Then: HTTP server listens on the specified port and serves files from /tmp/plantuml.nvim/

## Test Steps

- Case 1 (happy path): Server starts on specified port, serves SVG file with correct content-type
- Case 2 (CORS headers): Server includes Access-Control-Allow-Origin header in responses
- Case 3 (file not found): Server returns 404 for non-existent files
- Case 4 (directory listing): Server returns 403 or 404 for directory paths
- Case 5 (port busy): Server handles EADDRINUSE error gracefully

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor