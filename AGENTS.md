# AGENTS.md

Guidelines for agentic coding agents working in this repository.

## Project Overview

Neovim plugin for PlantUML integration:
- PlantUML preview in default browser (SVG)
- Real-time PlantUML utxt target preview in Neovim window
- High DPI PNG generation via Inkscape

## Commands

### Linting

```bash
luarocks install luacheck          # Install if needed
luacheck lua/ plugin/              # Lint all files
luacheck lua/plantuml/init.lua     # Lint single file
```

### Formatting

```bash
cargo install stylua               # Install if needed
stylua lua/ plugin/                # Format all files
stylua --check lua/ plugin/        # Check without modifying
```

### Testing

```bash
# Run all tests with Plenary
nvim --headless -c "PlenaryBustedDirectory lua/tests/ {minimal_init = 'lua/tests/minimal_init.lua'}"

# Run single test file
nvim --headless -c "PlenaryBustedFile lua/tests/test_module.lua"
```

## Code Style

### Indentation

- 2 spaces (Neovim plugin standard)
- No tabs

### Imports

```lua
-- Order: stdlib -> plugins -> local modules
local uv = vim.loop
local api = vim.api
local fn = vim.fn

local has_plenary, plenary = pcall(require, "plenary")
local config = require("plantuml.config")
```

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `preview_manager.lua` |
| Constants | SCREAMING_SNAKE_CASE | `DEFAULT_PORT` |
| Local functions | snake_case | `local function find_root()` |
| Exported functions | camelCase | `M.createPreview()` |
| Variables | snake_case | `local file_path` |

### Module Pattern

```lua
local M = {}

local state = { initialized = false }

M.setup = function(opts)
  opts = opts or {}
end

return M
```

### Error Handling

```lua
local ok, result = pcall(fn, args)
if not ok then
  vim.notify("Error: " .. result, vim.log.levels.ERROR)
  return nil
end
```

### Type Annotations (LuaCATS)

```lua
---@class PlantumlConfig
---@field java_cmd string
---@field plantuml_jar string

---@param opts PlantumlConfig
function M.setup(opts) end
```

### Command Registration

```lua
vim.api.nvim_create_user_command("PlantumlPreview", function(opts)
  require("plantuml").preview(opts)
end, { desc = "Preview PlantUML diagram", nargs = "?" })
```

## Project Structure

```
plantuml.nvim/
├── lua/plantuml/
│   ├── init.lua       -- Main entry
│   ├── config.lua     -- Configuration
│   ├── preview.lua    -- Preview logic
│   └── util.lua       -- Utilities
├── plugin/
│   └── plantuml.lua   -- Lazy-loaded entry
└── lua/tests/         -- Test files
```

## Dependencies

- **Required**: Neovim 0.8+, Java, plantuml.jar
- **Optional**: Inkscape (high-DPI PNG)

## Key Patterns

### Async Operations

```lua
local uv = vim.loop
uv.fs_open(filepath, "r", 438, function(err, fd)
  if err then return end
end)
```

### Process Execution

```lua
vim.system({ "java", "-jar", jar_path, "-tsvg", input }, { text = true },
  function(result)
    if result.code ~= 0 then
      vim.notify(result.stderr, vim.log.levels.ERROR)
    end
  end)
```

## Notes

- Temp files: `/tmp/plantuml.nvim/`
- Output files: `project-folder/umlout/`
- Project folder: first parent with `.git` or buffer's cwd
- File extensions: `.puml`, `.uml`