# Scenario: png_dpi Configuration Option

- Given: The plantuml.nvim plugin is loaded
- When: User calls `setup({ png_dpi = 400 })`
- Then: The configuration should store `png_dpi = 400`

## Test Steps

- Case 1 (happy path): User configures custom png_dpi value (e.g., 400)
- Case 2 (default value): User calls setup without png_dpi, should default to 800
- Case 3 (nil value): User passes nil for png_dpi, should use default 800

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor
