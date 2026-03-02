# Scenario: run_inkscape async execution

- Given: An SVG file path, PNG output path, and DPI value
- When: `run_inkscape(svg_path, png_path, dpi, callback)` is called
- Then: Inkscape command is executed asynchronously and callback receives result

## Test Steps

- Case 1 (happy path): Execute with valid SVG, expect success with stdout
- Case 2 (error path): Execute with invalid SVG file, expect failure with stderr
- Case 3 (command construction): Verify vim.system receives correct argument array with --export-filename and --export-dpi
- Case 4 (callback interface): Verify callback receives (success, output_or_error) tuple
- Case 5 (dpi parameter): Verify DPI is correctly passed to Inkscape

## Status

- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor