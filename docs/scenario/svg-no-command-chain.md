# Scenario: No Command Chain Triggers

- Given: SVG preview is active with autocmd registered
- When: The user saves a .puml file
- Then: Only SVG regeneration happens - no PlantumlCreateSVG/PNG/UTXT commands are triggered

## Test Steps

- Case 1 (critical): Autocmd handler calls executor.run_plantuml directly, NOT creator.create_svg
- Case 2 (critical): No PlantumlCreateSVG user command is executed
- Case 3 (critical): No PlantumlCreatePNG user command is executed
- Case 4 (critical): No PlantumlCreateUTXT user command is executed
- Case 5 (edge case): The generated SVG goes to /tmp/plantuml.nvim/, NOT to project umlout/ folder

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor