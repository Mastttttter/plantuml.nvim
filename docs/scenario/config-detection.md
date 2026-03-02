# Scenario: PlantUML Executable Detection

- Given: The config module is loaded
- When: setup() is called
- Then: The module detects the appropriate PlantUML command based on system availability

## Test Steps

- Case 1 (happy path): When vim.fn.executable('plantuml') returns 1, plantuml_cmd is 'plantuml'
- Case 2 (happy path): When plantuml not available but plantuml_jar is set, plantuml_cmd is 'java -jar /path/to/plantuml.jar'
- Case 3 (edge case): When neither plantuml nor plantuml_jar is available, plantuml_cmd is nil
- Case 4 (edge case): When plantuml available and plantuml_jar also set, prefer system plantuml

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor