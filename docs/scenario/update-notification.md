# Scenario: Update Notification Endpoint

- Given: Server is running with SSE clients connected
- When: Neovim sends POST /update with {filename, filepath}
- Then: Server reads SVG from filepath, updates state, and broadcasts "update" event to all clients

## Test Steps

- Case 1 (accept JSON): POST /update accepts JSON body with filename and filepath fields
- Case 2 (read SVG): Server reads SVG content from provided filepath
- Case 3 (update state): State is updated with new filename, svgContent, and lastUpdate
- Case 4 (broadcast update): All connected SSE clients receive "update" event
- Case 5 (missing fields): Returns 400 Bad Request if filename or filepath is missing
- Case 6 (file not found): Returns 404 Not Found if filepath does not exist

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor