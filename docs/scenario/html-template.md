# Scenario: HTML Template with UI Elements

- Given: Server is running with HTML template
- When: Client requests GET / endpoint
- Then: Server returns HTML page with title, centered SVG container, time display, and save reminder

## Test Steps

- Case 1 (HTML structure): Response contains DOCTYPE, html, head, and body tags
- Case 2 (title element): HTML contains <title> element with filename from state
- Case 3 (SVG container): HTML contains centered <div id="svg-container"> for SVG display
- Case 4 (time display): HTML contains element to show last update time
- Case 5 (save reminder): HTML contains reminder text about saving buffer
- Case 6 (EventSource connection): HTML includes JavaScript to connect to /events endpoint

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor