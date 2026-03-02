# Scenario: create_svg Function

- Given: A PlantUML buffer is open and PlantUML is available
- When: `create_svg()` is called
- Then: SVG file is generated in `umlout/svg/` and user receives success notification with output path

## Test Steps

- Case 1 (happy path): Buffer with valid PlantUML content, SVG generated successfully
- Case 2 (error case): PlantUML execution fails, user receives error notification
- Case 3 (no buffer): No buffer is open, function handles gracefully
- Case 4 (directory creation): Output directory doesn't exist, it is created automatically

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor