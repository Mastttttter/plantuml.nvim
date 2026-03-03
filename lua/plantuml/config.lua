--- Configuration module for plantuml.nvim
--- Handles setup, defaults, and tool detection

local M = {}

--- Default configuration
local DEFAULTS = {
  java_cmd = "java",
  plantuml_jar = nil,
  inkscape_cmd = "inkscape",
  server_port = 8912,
  png_dpi = 800,
  plantuml_cmd = nil, -- Detected at setup time
}

--- Current configuration (starts with defaults)
local config = vim.deepcopy(DEFAULTS)

--- Check if a command is available
---@param cmd string Command name to check
---@return boolean true if available
local function is_executable(cmd)
  return vim.fn.executable(cmd) == 1
end

--- Detect the appropriate plantuml command
---@return string|nil The plantuml command or nil if not found
local function detect_plantuml_cmd()
  -- Prefer system plantuml if available
  if is_executable("plantuml") then
    return "plantuml"
  end

  -- Fall back to java -jar pattern if plantuml_jar is configured
  if config.plantuml_jar then
    if is_executable(config.java_cmd) then
      return config.java_cmd .. " -jar " .. config.plantuml_jar
    else
      vim.notify(
        "plantuml.nvim: java not found. Required for plantuml_jar: " .. config.java_cmd,
        vim.log.levels.ERROR
      )
      return nil
    end
  end

  -- Neither available
  return nil
end

--- Validate required tools and warn about missing ones
local function validate_tools()
  -- Check if we have a working plantuml command
  if not config.plantuml_cmd then
    local has_plantuml = is_executable("plantuml")
    
    if not has_plantuml and not config.plantuml_jar then
      vim.notify(
        "plantuml.nvim: Neither 'plantuml' command nor plantuml_jar configured. "
          .. "Please install plantuml or set plantuml_jar path.",
        vim.log.levels.ERROR
      )
    end
  end

  -- Check inkscape (optional, warn only)
  if not is_executable(config.inkscape_cmd) then
    vim.notify(
      "plantuml.nvim: inkscape not found. PNG generation will not work: " .. config.inkscape_cmd,
      vim.log.levels.WARN
    )
  end
end

--- Setup configuration with user options
---@param opts table|nil User configuration options
---@return table The merged configuration
function M.setup(opts)
  opts = opts or {}

  -- Merge user options with defaults
  for key, value in pairs(opts) do
    if value ~= nil then
      config[key] = value
    end
  end

  -- Detect plantuml command
  config.plantuml_cmd = detect_plantuml_cmd()

  -- Validate tools
  validate_tools()

  return config
end

--- Get current configuration
---@return table The current configuration
function M.get()
  return config
end

return M
