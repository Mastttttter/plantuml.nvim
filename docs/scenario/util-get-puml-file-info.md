# Scenario: get_puml_file_info Function

- Given: The current Neovim buffer contains a PlantUML file
- When: The function is called (no parameters, uses current buffer)
- Then: Returns a table with file info including filename without extension

## Test Steps

- Case 1 (happy path): Valid .puml file - returns filename without extension
- Case 2 (.uml extension): File with .uml extension - returns filename without extension
- Case 3 (no extension): File without extension - returns full filename
- Case 4 (nested path): File in subdirectory - extracts just the filename
- Case 5 (returns table): Function returns a table with multiple fields (name, fullpath, etc.)

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [x] Refactor implementation without breaking test
- [x] Run test and confirm still passing after refactor