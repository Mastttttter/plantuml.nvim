--- Creator module for plantuml.nvim
--- Provides file creation functions for SVG, PNG, and UTXT formats

local M = {}

local uv = vim.loop
local executor = require("plantuml.executor")
local util = require("plantuml.util")

--- Default DPI for PNG export
local DEFAULT_DPI = 300

--- Ensure output directory exists
--- @param dir string Directory path to create
--- @return boolean true if directory exists or was created
local function ensure_output_dir(dir)
  -- Check if it already exists
  local stat = uv.fs_stat(dir)
  if stat then
    return true
  end

  -- Create parent directories first
  local parent = vim.fn.fnamemodify(dir, ":h")
  if parent ~= dir then
    local parent_stat = uv.fs_stat(parent)
    if not parent_stat then
      ensure_output_dir(parent)
    end
  end

  -- Create the directory
  local ok, err = uv.fs_mkdir(dir, 493) -- 0755
  if not ok and err ~= "EEXIST" then
    vim.notify("plantuml.nvim: Failed to create directory: " .. err, vim.log.levels.ERROR)
    return false
  end

  return true
end

--- Create SVG output from current buffer
--- @param callback function|nil Callback function(success) called when complete
function M.create_svg(callback)
  -- Get file info
  local info = util.get_puml_file_info()
  if not info then
    vim.notify("plantuml.nvim: No PlantUML buffer found", vim.log.levels.ERROR)
    if callback then
      callback(false)
    end
    return
  end

  -- Get output directory
  local output_dir = util.get_output_dir(info.fullpath, "svg")
  local output_path = output_dir .. "/" .. info.name .. ".svg"

  -- Ensure output directory exists
  if not ensure_output_dir(output_dir) then
    if callback then
      callback(false)
    end
    return
  end

  -- Run PlantUML
  executor.run_plantuml(info.fullpath, output_path, "svg", function(success, output)
    if success then
      vim.notify(
        "plantuml.nvim: SVG created: " .. output_path,
        vim.log.levels.INFO
      )
    end
    if callback then
      callback(success)
    end
  end)
end

--- Create PNG output from current buffer (via SVG then Inkscape)
--- @param callback function|nil Callback function(success) called when complete
function M.create_png(callback)
  -- Get file info
  local info = util.get_puml_file_info()
  if not info then
    vim.notify("plantuml.nvim: No PlantUML buffer found", vim.log.levels.ERROR)
    if callback then
      callback(false)
    end
    return
  end

  -- Get output directories
  local svg_dir = util.get_output_dir(info.fullpath, "svg")
  local png_dir = util.get_output_dir(info.fullpath, "png")
  local svg_path = svg_dir .. "/" .. info.name .. ".svg"
  local png_path = png_dir .. "/" .. info.name .. ".png"

  -- Ensure output directories exist
  if not ensure_output_dir(svg_dir) then
    if callback then
      callback(false)
    end
    return
  end
  if not ensure_output_dir(png_dir) then
    if callback then
      callback(false)
    end
    return
  end

  -- Step 1: Generate SVG
  executor.run_plantuml(info.fullpath, svg_path, "svg", function(success, output)
    if not success then
      vim.notify(
        "plantuml.nvim: Failed to generate SVG for PNG conversion",
        vim.log.levels.ERROR
      )
      if callback then
        callback(false)
      end
      return
    end

    -- Step 2: Convert SVG to PNG using Inkscape
    executor.run_inkscape(svg_path, png_path, DEFAULT_DPI, function(inkscape_success, inkscape_output)
      if inkscape_success then
        vim.notify(
          "plantuml.nvim: PNG created: " .. png_path,
          vim.log.levels.INFO
        )
      end
      if callback then
        callback(inkscape_success)
      end
    end)
  end)
end

--- Create UTXT output from current buffer
--- @param callback function|nil Callback function(success) called when complete
function M.create_utxt(callback)
  -- Get file info
  local info = util.get_puml_file_info()
  if not info then
    vim.notify("plantuml.nvim: No PlantUML buffer found", vim.log.levels.ERROR)
    if callback then
      callback(false)
    end
    return
  end

  -- Get output directory
  local output_dir = util.get_output_dir(info.fullpath, "utxt")
  local output_path = output_dir .. "/" .. info.name .. ".utxt"

  -- Ensure output directory exists
  if not ensure_output_dir(output_dir) then
    if callback then
      callback(false)
    end
    return
  end

  -- Run PlantUML
  executor.run_plantuml(info.fullpath, output_path, "utxt", function(success, output)
    if success then
      vim.notify(
        "plantuml.nvim: UTXT created: " .. output_path,
        vim.log.levels.INFO
      )
    end
    if callback then
      callback(success)
    end
  end)
end

return M