# Scenario: Remove File Watcher

- Given: Server code exists
- When: Server is refactored to use HTTP notification
- Then: No fileWatcher code exists in server.js

## Test Steps

- Case 1 (no fs.watch): No fs.watch or fs.watchFile calls in server.js
- Case 2 (no startFileWatcher): No startFileWatcher function definition
- Case 3 (no fileWatcher variable): No fileWatcher variable declaration
- Case 4 (no watch import): fs module is imported but only for fs.readFile, fs.existsSync, fs.statSync, fs.access, fs.mkdirSync operations

## Status
- [x] Write scenario document
- [ ] Write solid test according to document
- [ ] Run test and watch it failing
- [ ] Implement to make test pass
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor