# Scenario: Configuration Schema Definition

- Given: The config module is loaded
- When: A user calls setup() with no options
- Then: The module returns a configuration table with default values for java_cmd, plantuml_jar, inkscape_cmd, server_port

## Test Steps

- Case 1 (happy path): setup() with no opts returns all default values
- Case 2 (edge case): setup() with empty table {} returns defaults
- Case 3 (edge case): get() before setup() returns defaults

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor