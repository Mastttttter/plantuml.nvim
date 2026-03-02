# Scenario: Setup Function with Merging

- Given: The config module is loaded
- When: A user calls setup({ java_cmd = "/usr/bin/java", server_port = 9000 })
- Then: The returned configuration has java_cmd = "/usr/bin/java" and server_port = 9000, while other options retain defaults

## Test Steps

- Case 1 (happy path): setup() with partial opts merges correctly
- Case 2 (edge case): setup() with nil values uses defaults
- Case 3 (edge case): setup() with all opts specified overrides all defaults

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor