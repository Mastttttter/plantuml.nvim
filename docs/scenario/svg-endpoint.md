# Scenario: SVG Content Endpoint

- Given: Server has SVG content in state
- When: Client requests GET /svg endpoint
- Then: Server returns cached SVG content with proper content-type header

## Test Steps

- Case 1 (cached content): Returns SVG content stored in state
- Case 2 (content-type): Response includes Content-Type: image/svg+xml header
- Case 3 (empty state): Returns empty response with 200 status when state is empty
- Case 4 (CORS headers): Response includes Access-Control-Allow-Origin: * header

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor