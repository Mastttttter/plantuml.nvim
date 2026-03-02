# Scenario: update_preview() function

- Given: A preview may or may not already exist
- When: `update_preview()` is called
- Then: Existing preview is reused, or new split is created if none exists

## Test Steps

- Case 1 (happy path): Preview window exists, content is updated in place
- Case 2 (happy path): No preview window exists, new vertical split created to the right
- Case 3 (edge case): Preview buffer exists but in different window, reuse the buffer
- Case 4 (edge case): Multiple calls to update_preview() should not create multiple windows
- Case 5 (edge case): Content is replaced, not appended

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor