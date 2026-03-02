# Scenario: create_png Function

- Given: A PlantUML buffer is open, PlantUML and Inkscape are available
- When: `create_png()` is called
- Then: SVG is generated first, then converted to PNG in `umlout/png/`, user receives success notification with output path

## Test Steps

- Case 1 (happy path): Buffer with valid PlantUML content, PNG generated successfully via SVG chaining
- Case 2 (svg failure): SVG generation fails, PNG not attempted, error notification shown
- Case 3 (inkscape failure): SVG succeeds but Inkscape fails, error notification shown
- Case 4 (no inkscape): Inkscape not available, user receives appropriate error
- Case 5 (dpi config): Uses configured DPI value for PNG export

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor