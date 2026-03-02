--- Plugin entry point for plantuml.nvim
--- Registers user commands and sets up autocmds

local api = vim.api

-- Create augroup for plugin autocmds
api.nvim_create_augroup("PlantumlPlugin", { clear = true })

--- Get the plantuml module (lazy require)
---@return table The plantuml module
local function get_plantuml()
  return require("plantuml")
end

--- Register user commands
local function register_commands()
  -- PlantumlPreview: Preview in browser (SVG)
  api.nvim_create_user_command("PlantumlPreview", function()
    get_plantuml().preview()
  end, {
    desc = "Preview PlantUML diagram in browser",
    nargs = 0,
  })

  -- PlantumlPreviewUTXT: Preview as UTXT in split window
  api.nvim_create_user_command("PlantumlPreviewUTXT", function()
    get_plantuml().preview_utxt()
  end, {
    desc = "Preview PlantUML diagram as ASCII art in split window",
    nargs = 0,
  })

  -- PlantumlCreateSVG: Create SVG file
  api.nvim_create_user_command("PlantumlCreateSVG", function()
    get_plantuml().create_svg()
  end, {
    desc = "Create SVG file from PlantUML diagram",
    nargs = 0,
  })

  -- PlantumlCreatePNG: Create PNG file (via Inkscape)
  api.nvim_create_user_command("PlantumlCreatePNG", function()
    get_plantuml().create_png()
  end, {
    desc = "Create PNG file from PlantUML diagram (high DPI via Inkscape)",
    nargs = 0,
  })

  -- PlantumlCreateUTXT: Create UTXT file
  api.nvim_create_user_command("PlantumlCreateUTXT", function()
    get_plantuml().create_utxt()
  end, {
    desc = "Create UTXT (ASCII art) file from PlantUML diagram",
    nargs = 0,
  })
end

--- Cleanup on VimLeave
local function cleanup()
  -- Stop the preview server if running
  local server = require("plantuml.server")
  server.stop_server()
end

--- Setup the plugin
local function setup()
  -- Register commands
  register_commands()

  -- Register VimLeave autocmd for cleanup
  api.nvim_create_autocmd("VimLeave", {
    group = "PlantumlPlugin",
    callback = cleanup,
    desc = "Cleanup PlantUML server and resources on exit",
  })
end

-- Run setup
setup()