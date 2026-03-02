# Scenario: Tool Validation with Error Messages

- Given: The config module is loaded
- When: setup() is called but required tools are missing
- Then: The module displays clear error messages via vim.notify

## Test Steps

- Case 1 (happy path): When both plantuml and java are available, no error
- Case 2 (error case): When plantuml not available, plantuml_jar not set, and java not available, show error about missing plantuml/java
- Case 3 (error case): When plantuml_jar is set but java not available, show error about missing java
- Case 4 (warning case): When inkscape not available, show warning (not error)

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor