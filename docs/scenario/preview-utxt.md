# Scenario: preview_utxt() function

- Given: A PlantUML file is open in the current buffer
- When: `preview_utxt()` is called
- Then: A vertical split is created on the right with UTXT content

## Test Steps

- Case 1 (happy path): Open .puml file, call preview_utxt(), verify split created with UTXT buffer
- Case 2 (happy path): Open .uml file, call preview_utxt(), verify split created with UTXT buffer
- Case 3 (edge case): Call preview_utxt() with no buffer, verify error handling
- Case 4 (edge case): Call preview_utxt() with non-plantuml file, verify error handling
- Case 5 (edge case): Buffer has `plantuml_preview` variable set after creation

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor