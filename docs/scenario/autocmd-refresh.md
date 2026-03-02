# Scenario: BufWritePost autocmd for auto-refresh

- Given: A BufWritePost autocmd is registered for .puml and .uml files
- When: A PlantUML file is saved
- Then: Preview is automatically refreshed if it's open

## Test Steps

- Case 1 (happy path): Save .puml file with preview open, preview refreshes automatically
- Case 2 (happy path): Save .uml file with preview open, preview refreshes automatically
- Case 3 (edge case): Save .puml file with no preview open, no error occurs
- Case 4 (edge case): Save non-plantuml file, no refresh triggered
- Case 5 (edge case): Multiple saves trigger multiple refreshes (no debouncing required)

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor