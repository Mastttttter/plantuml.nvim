# Scenario: SVG Preview State Tracking

- Given: The preview module is loaded
- When: SVG preview is started or stopped
- Then: The module tracks the active/inactive state of SVG preview

## Test Steps

- Case 1 (happy path): After preview_svg() starts, is_svg_preview_active() returns true
- Case 2 (happy path): After stopping preview, is_svg_preview_active() returns false
- Case 3 (edge case): Initially, is_svg_preview_active() returns false
- Case 4 (edge case): Multiple preview_svg() calls don't create duplicate state

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor