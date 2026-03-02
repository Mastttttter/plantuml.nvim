# Scenario: Cleanup function

- Given: Autocmd group exists for preview refresh
- When: `cleanup()` is called
- Then: Autocmd is removed and internal state is cleared

## Test Steps

- Case 1 (happy path): Call cleanup(), verify autocmd group is removed
- Case 2 (happy path): Call cleanup(), verify internal state cleared
- Case 3 (edge case): Call cleanup() when no autocmd exists, no error
- Case 4 (edge case): Call cleanup() twice in succession, second call is no-op
- Case 5 (edge case): After cleanup, new preview_utxt() call works correctly

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor