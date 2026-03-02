# Scenario: find_preview_window() function

- Given: Preview buffer may or may not exist
- When: `find_preview_window()` is called
- Then: Returns window ID if preview exists, nil otherwise

## Test Steps

- Case 1 (happy path): Preview window exists, returns its window ID
- Case 2 (happy path): Multiple windows exist including preview, returns correct window ID
- Case 3 (edge case): No preview window exists, returns nil
- Case 4 (edge case): Preview buffer exists but window was closed, returns nil
- Case 5 (edge case): Buffer has `plantuml_preview` variable set to false, not counted as preview

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor