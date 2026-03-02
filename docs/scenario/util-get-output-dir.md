# Scenario: get_output_dir Function

- Given: A buffer path and a subdirectory name
- When: The function is called with both parameters
- Then: Returns the path `<project-folder>/umlout/<subdir>`

## Test Steps

- Case 1 (happy path): Valid buffer path and subdir - returns correct output path
- Case 2 (git root): Buffer in git repo - uses git root as project folder
- Case 3 (no git): Buffer not in git repo - uses cwd as project folder
- Case 4 (different subdirs): Different subdir names (svg, png, utxt) - all work correctly
- Case 5 (nil subdir): Nil subdir - returns `<project-folder>/umlout/`

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor