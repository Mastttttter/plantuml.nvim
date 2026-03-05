# Scenario: Autocmd Cleanup on Preview Stop

- Given: SVG preview is active with autocmd registered
- When: The preview is stopped or source buffer is closed
- Then: The autocmd is cleaned up and removed

## Test Steps

- Case 1 (happy path): Calling stop_svg_preview() unregisters the autocmd
- Case 2 (happy path): Closing source buffer triggers cleanup
- Case 3 (edge case): Calling unregister_svg_autocmd() twice doesn't error
- Case 4 (edge case): Starting new preview after cleanup works correctly

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor