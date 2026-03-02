--- Executor module for plantuml.nvim
--- Provides async command execution wrappers for PlantUML and Inkscape

local M = {}

local config = require("plantuml.config")

--- Build PlantUML command arguments
--- @param input string Input file path
--- @param output_path string Output file path
--- @param format string Output format (svg, png, utxt)
--- @return table Command arguments array
local function build_plantuml_cmd(input, output_path, format)
  local cfg = config.get()
  local plantuml_cmd = cfg.plantuml_cmd

  -- Parse the plantuml_cmd into components
  local cmd = {}

  if plantuml_cmd:match("^plantuml$") then
    -- Simple plantuml command
    table.insert(cmd, "plantuml")
  else
    -- Split the command string (e.g., "java -jar /path/to/plantuml.jar")
    for part in plantuml_cmd:gmatch("%S+") do
      table.insert(cmd, part)
    end
  end

  -- Add format flag
  table.insert(cmd, "-t" .. format)

  -- Add output directory flag
  local output_dir = vim.fn.fnamemodify(output_path, ":h")
  table.insert(cmd, "-o")
  table.insert(cmd, output_dir)

  -- Add input file
  table.insert(cmd, input)

  return cmd
end

--- Run PlantUML command asynchronously
--- @param input string Input file path
--- @param output_path string Output file path
--- @param format string Output format (svg, png, utxt)
--- @param callback function Callback function(success, output_or_error)
function M.run_plantuml(input, output_path, format, callback)
  local cfg = config.get()
  local plantuml_cmd = cfg.plantuml_cmd

  -- Check if plantuml command is available
  if not plantuml_cmd then
    vim.notify(
      "plantuml.nvim: PlantUML command not available. Please install plantuml or configure plantuml_jar.",
      vim.log.levels.ERROR
    )
    callback(false, "PlantUML command not available")
    return
  end

  local cmd = build_plantuml_cmd(input, output_path, format)

  vim.system(cmd, { text = true }, function(result)
    if result.code ~= 0 then
      local error_msg = result.stderr
      if error_msg == "" then
        error_msg = "PlantUML exited with code " .. result.code
      end
      vim.notify(
        "plantuml.nvim: PlantUML error (exit code " .. result.code .. "): " .. error_msg,
        vim.log.levels.ERROR
      )
      callback(false, error_msg)
    else
      callback(true, result.stdout)
    end
  end)
end

--- Run Inkscape command asynchronously
--- @param svg_path string Input SVG file path
--- @param png_path string Output PNG file path
--- @param dpi number DPI value for export
--- @param callback function Callback function(success, output_or_error)
function M.run_inkscape(svg_path, png_path, dpi, callback)
  local cfg = config.get()
  local inkscape_cmd = cfg.inkscape_cmd or "inkscape"

  local cmd = {
    inkscape_cmd,
    "--export-filename",
    png_path,
    "--export-dpi",
    tostring(dpi),
    svg_path,
  }

  vim.system(cmd, { text = true }, function(result)
    if result.code ~= 0 then
      local error_msg = result.stderr
      if error_msg == "" then
        error_msg = "Inkscape exited with code " .. result.code
      end
      vim.notify(
        "plantuml.nvim: Inkscape error (exit code " .. result.code .. "): " .. error_msg,
        vim.log.levels.ERROR
      )
      callback(false, error_msg)
    else
      callback(true, result.stdout)
    end
  end)
end

return M