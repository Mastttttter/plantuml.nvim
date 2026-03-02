--- Main entry point for plantuml.nvim
--- Exports public API and provides setup function

local M = {}

local config = require("plantuml.config")
local preview = require("plantuml.preview")
local creator = require("plantuml.creator")

--- Setup the plugin with user configuration
---@param opts table|nil User configuration options
---@return table The module table for chaining
function M.setup(opts)
  config.setup(opts)
  return M
end

--- Preview the current PlantUML file in browser (SVG format)
---@param callback function|nil Optional callback function
function M.preview(callback)
  preview.preview_svg(callback)
end

--- Preview the current PlantUML file as UTXT in a split window
---@param callback function|nil Optional callback function
function M.preview_utxt(callback)
  preview.preview_utxt(callback)
end

--- Create SVG output from the current PlantUML file
---@param callback function|nil Optional callback function(success)
function M.create_svg(callback)
  creator.create_svg(callback)
end

--- Create PNG output from the current PlantUML file (via SVG + Inkscape)
---@param callback function|nil Optional callback function(success)
function M.create_png(callback)
  creator.create_png(callback)
end

--- Create UTXT output from the current PlantUML file
---@param callback function|nil Optional callback function(success)
function M.create_utxt(callback)
  creator.create_utxt(callback)
end

return M