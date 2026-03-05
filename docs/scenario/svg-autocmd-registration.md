# Scenario: BufWritePost Autocmd Registration for SVG Preview

- Given: SVG preview is about to start
- When: preview_svg() is called
- Then: A BufWritePost autocmd is registered for .puml and .uml files

## Test Steps

- Case 1 (happy path): After preview_svg(), register_svg_autocmd() creates the autocmd
- Case 2 (happy path): The autocmd triggers on .puml file save
- Case 3 (happy path): The autocmd triggers on .uml file save
- Case 4 (edge case): The autocmd does NOT trigger on non-.puml/.uml file save
- Case 5 (edge case): Multiple register_svg_autocmd() calls don't create duplicates

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor