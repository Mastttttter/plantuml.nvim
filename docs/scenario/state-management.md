# Scenario: State Management

- Given: Server is running with HTTP notification architecture
- When: Server receives updates via POST /update endpoint
- Then: Server maintains and updates state with filename, svgContent, and lastUpdate timestamp

## Test Steps

- Case 1 (initial state): Server starts with empty state (null filename, empty svgContent, null lastUpdate)
- Case 2 (update state): POST /update with filename and filepath updates all three state properties
- Case 3 (svg content read): SVG content is read from provided filepath and stored in state
- Case 4 (timestamp update): lastUpdate is set to current time on each update

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor