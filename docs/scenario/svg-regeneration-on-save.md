# Scenario: SVG Regeneration on Save

- Given: SVG preview is active with a .puml file open
- When: The user saves the .puml file
- Then: The SVG is regenerated in /tmp/plantuml.nvim/ (not project output)

## Test Steps

- Case 1 (happy path): Saving .puml file triggers SVG regeneration to temp dir
- Case 2 (happy path): Saving .uml file triggers SVG regeneration to temp dir
- Case 3 (edge case): SVG is generated with correct filename based on source file
- Case 4 (edge case): SSE script is injected into regenerated SVG
- Case 5 (critical): PlantumlCreateSVG command is NOT called (direct executor call)
- Case 6 (critical): PlantumlCreatePNG command is NOT called
- Case 7 (critical): PlantumlCreateUTXT command is NOT called

## Status
- [x] Write scenario document
- [x] Write solid test according to document
- [x] Run test and watch it failing
- [x] Implement to make test pass
- [x] Run test and confirm it passed
- [ ] Run test and confirm it passed
- [ ] Refactor implementation without breaking test
- [ ] Run test and confirm still passing after refactor