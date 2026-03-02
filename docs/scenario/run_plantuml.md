# Scenario: run_plantuml async execution

- Given: A PlantUML input file and output path
- When: `run_plantuml(input, output_path, format, callback)` is called
- Then: PlantUML command is executed asynchronously and callback receives result

## Test Steps

- Case 1 (happy path - SVG): Execute with valid input, format "svg", expect success with stdout
- Case 2 (happy path - PNG): Execute with valid input, format "png", expect success with stdout
- Case 3 (happy path - UTXT): Execute with valid input, format "utxt", expect success with stdout
- Case 4 (error path): Execute with invalid input file, expect failure with stderr
- Case 5 (command construction): Verify vim.system receives correct argument array
- Case 6 (callback interface): Verify callback receives (success, output_or_error) tuple

## Status

- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor