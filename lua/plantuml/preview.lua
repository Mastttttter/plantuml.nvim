--- Preview module for plantuml.nvim
--- Provides UTXT preview with smart window management and auto-refresh

local M = {}

local api = vim.api
local uv = vim.loop
local executor = require("plantuml.executor")
local util = require("plantuml.util")

-- State for preview management
local state = {
  preview_bufnr = nil,
  preview_winnr = nil,
  source_bufnr = nil,
  autocmd_id = nil,
  -- SVG preview state
  svg_preview_active = false,
  svg_autocmd_id = nil,
  svg_source_bufnr = nil,
}

--- Inject SSE auto-refresh script into SVG file
--- This is only called for preview SVG files, not for exported files
--- @param svg_path string Path to the SVG file to inject script into
--- @param port number Server port for SSE connection
local function inject_script(svg_path, port)
  -- Read the SVG file
  local fd, err = uv.fs_open(svg_path, "r", 438)
  if not fd then
    vim.notify("plantuml.nvim: Failed to open SVG for injection: " .. (err or "unknown error"), vim.log.levels.WARN)
    return false
  end

  local stat = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return false
  end

  local data = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not data then
    return false
  end

  -- Create the SSE listener script
  -- This script connects to the /events endpoint and reloads on refresh
  local script = string.format([[
<script type="text/javascript">
(function() {
  var eventSource = new EventSource('http://localhost:%d/events');
  eventSource.onmessage = function(e) {
    if (e.data === 'refresh') {
      location.reload();
    }
  };
  eventSource.onerror = function() {
    // Reconnect after 1 second on error
    setTimeout(function() {
      location.reload();
    }, 1000);
  };
})();
</script>
]], port)

  -- Insert script before closing </svg> tag
  local injected_svg = data:gsub("</svg>", script .. "</svg>")

  -- Check if injection was successful
  if injected_svg == data then
    -- No </svg> tag found or injection failed
    vim.notify("plantuml.nvim: Could not find </svg> tag for script injection", vim.log.levels.WARN)
    return false
  end

  -- Write the modified SVG back
  local fd2, err2 = uv.fs_open(svg_path, "w", 438)
  if not fd2 then
    vim.notify("plantuml.nvim: Failed to write injected SVG: " .. (err2 or "unknown error"), vim.log.levels.WARN)
    return false
  end

  uv.fs_write(fd2, injected_svg, 0)
  uv.fs_close(fd2)

  return true
end

--- Find existing buffer by name
--- @param name string Buffer name to search for
--- @return number|nil Buffer number if found, nil otherwise
local function find_buffer_by_name(name)
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) then
      local ok, buf_name = pcall(api.nvim_buf_get_name, buf)
      if ok and buf_name == name then
        return buf
      end
    end
  end
  return nil
end

--- Find existing preview window
--- @return number|nil Window ID if preview exists, nil otherwise
function M.find_preview_window()
  -- Check if our tracked buffer still exists and is valid
  if state.preview_bufnr and api.nvim_buf_is_valid(state.preview_bufnr) then
    -- Find window displaying this buffer
    for _, win in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_get_buf(win) == state.preview_bufnr then
        return win
      end
    end
  end

  -- Also check for buffers with our marker
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) then
      local ok, is_preview = pcall(api.nvim_buf_get_var, buf, "plantuml_preview")
      if ok and is_preview then
        -- Update our state
        state.preview_bufnr = buf
        for _, win in ipairs(api.nvim_list_wins()) do
          if api.nvim_win_get_buf(win) == buf then
            return win
          end
        end
      end
    end
  end

  return nil
end

--- Generate UTXT content for preview
--- @param callback function Callback function(content_or_nil)
local function generate_utxt_content(callback)
  local info = util.get_puml_file_info()
  if not info then
    vim.notify("plantuml.nvim: No PlantUML buffer found", vim.log.levels.ERROR)
    callback(nil)
    return
  end

  -- Ensure temp directory exists
  local temp_dir = util.ensure_temp_dir()
  if not temp_dir then
    callback(nil)
    return
  end

  -- Generate temp output path
  local output_path = temp_dir .. "/" .. info.name .. "_preview.utxt"

  -- Run PlantUML
  executor.run_plantuml(info.fullpath, output_path, "utxt", function(success, _)
    if not success then
      callback(nil)
      return
    end

    -- Read the generated file (must use vim.schedule to avoid E5560 error)
    vim.schedule(function()
      -- Find the actual generated file (PlantUML may use a different name)
      local actual_file = util.find_newest_file(temp_dir, "utxt")
      if not actual_file then
        vim.notify("plantuml.nvim: No utxt file found in temp directory", vim.log.levels.ERROR)
        callback(nil)
        return
      end

      local content = vim.fn.readfile(actual_file)
      if content and #content > 0 then
        callback(content)
      else
        callback(nil)
      end
    end)
  end)
end

--- Update the preview buffer with new content
--- @param content table Array of lines
local function update_preview_buffer(content)
  if not state.preview_bufnr or not api.nvim_buf_is_valid(state.preview_bufnr) then
    return
  end

  -- Make buffer modifiable temporarily
  api.nvim_buf_set_option(state.preview_bufnr, "modifiable", true)

  -- Set buffer content
  api.nvim_buf_set_lines(state.preview_bufnr, 0, -1, false, content)

  -- Reset options
  api.nvim_buf_set_option(state.preview_bufnr, "modified", false)
  api.nvim_buf_set_option(state.preview_bufnr, "modifiable", false)
end

--- Clean up preview state when buffer is closed
local function on_preview_buffer_closed()
  -- Check if this is our preview buffer being closed
  state.preview_bufnr = nil
  state.preview_winnr = nil
  state.source_bufnr = nil
  M.unregister_autocmd()
end

--- Create a new preview buffer and window
--- @param content table Array of lines
local function create_preview_window(content)
  -- Check for and delete any existing buffer with the same name
  -- This handles the case where the preview window was closed directly
  -- but the buffer still exists with name "plantuml://preview"
  local existing_buf = find_buffer_by_name("plantuml://preview")
  if existing_buf then
    -- Delete the stale buffer to avoid E95 error
    pcall(api.nvim_buf_delete, existing_buf, { force = true })
  end

  -- Create a new buffer
  state.preview_bufnr = api.nvim_create_buf(false, true) -- scratch buffer, no file

  -- Set buffer name and mark as preview
  api.nvim_buf_set_name(state.preview_bufnr, "plantuml://preview")
  api.nvim_buf_set_var(state.preview_bufnr, "plantuml_preview", true)

  -- Set buffer content
  api.nvim_buf_set_lines(state.preview_bufnr, 0, -1, false, content)

  -- Set buffer options
  api.nvim_buf_set_option(state.preview_bufnr, "buftype", "nofile")
  api.nvim_buf_set_option(state.preview_bufnr, "swapfile", false)
  api.nvim_buf_set_option(state.preview_bufnr, "modifiable", false)
  api.nvim_buf_set_option(state.preview_bufnr, "modified", false)
  api.nvim_buf_set_option(state.preview_bufnr, "filetype", "plantuml_preview")

  -- Store source buffer
  state.source_bufnr = api.nvim_get_current_buf()

  -- Create vertical split to the right
  api.nvim_command("rightbelow vsplit")
  state.preview_winnr = api.nvim_get_current_win()

  -- Set the buffer in the new window
  api.nvim_win_set_buf(state.preview_winnr, state.preview_bufnr)

  -- Set window options
  api.nvim_win_set_option(state.preview_winnr, "number", false)
  api.nvim_win_set_option(state.preview_winnr, "relativenumber", false)
  api.nvim_win_set_option(state.preview_winnr, "wrap", true)
  api.nvim_win_set_option(state.preview_winnr, "cursorline", false)

  -- Return to source window
  api.nvim_set_current_win(api.nvim_get_current_win())

  -- Register buffer cleanup on BufWipeout
  -- This ensures state is cleaned when user closes preview window directly
  api.nvim_create_autocmd("BufWipeout", {
    buffer = state.preview_bufnr,
    callback = on_preview_buffer_closed,
    desc = "Clean up preview state when buffer is wiped out",
  })

  -- Register autocmd for auto-refresh
  M.register_autocmd()

  vim.notify("plantuml.nvim: Preview window created", vim.log.levels.INFO)
end

--- Register BufWritePost autocmd for auto-refresh
function M.register_autocmd()
  -- Remove existing autocmd if any
  M.unregister_autocmd()

  -- Create augroup
  api.nvim_create_augroup("PlantumlPreview", { clear = true })

  -- Register BufWritePost autocmd for .puml and .uml files
  state.autocmd_id = api.nvim_create_autocmd("BufWritePost", {
    group = "PlantumlPreview",
    pattern = { "*.puml", "*.uml" },
    callback = function()
      -- Only refresh if preview is open
      if M.find_preview_window() then
        M.refresh_preview()
      end
    end,
    desc = "Auto-refresh PlantUML preview on save",
  })
end

--- Unregister the autocmd
function M.unregister_autocmd()
  if state.autocmd_id then
    pcall(api.nvim_del_autocmd, state.autocmd_id)
    state.autocmd_id = nil
  end
end

--- Refresh the preview content
function M.refresh_preview()
  generate_utxt_content(function(content)
    if content then
      update_preview_buffer(content)
      vim.notify("plantuml.nvim: Preview updated", vim.log.levels.INFO)
    end
  end)
end

--- Main preview function
--- Creates or updates the UTXT preview window
function M.preview_utxt()
  -- Check if preview window already exists
  local existing_win = M.find_preview_window()

  if existing_win then
    -- Update existing preview
    generate_utxt_content(function(content)
      if content then
        update_preview_buffer(content)
        vim.notify("plantuml.nvim: Preview updated", vim.log.levels.INFO)
      end
    end)
  else
    -- Create new preview
    generate_utxt_content(function(content)
      if content then
        create_preview_window(content)
      end
    end)
  end
end

--- Close the preview window
function M.close_preview()
  local win = M.find_preview_window()
  if win then
    api.nvim_win_close(win, true)
  end

  -- Clean up state
  state.preview_bufnr = nil
  state.preview_winnr = nil
  state.source_bufnr = nil
  M.unregister_autocmd()
end

--- Check if SVG preview is active
---@return boolean True if SVG preview is active
function M.is_svg_preview_active()
  return state.svg_preview_active or false
end

--- Register BufWritePost autocmd for SVG preview auto-refresh
function M.register_svg_autocmd()
  M.unregister_svg_autocmd()

  api.nvim_create_augroup("PlantumlSvgPreview", { clear = true })

  state.svg_autocmd_id = api.nvim_create_autocmd("BufWritePost", {
    group = "PlantumlSvgPreview",
    pattern = { "*.puml", "*.uml" },
    callback = function()
      if M.is_svg_preview_active() then
        M.refresh_svg_preview()
      end
    end,
    desc = "Auto-refresh SVG preview on save",
  })
end

--- Unregister the SVG autocmd
function M.unregister_svg_autocmd()
  if state.svg_autocmd_id then
    pcall(api.nvim_del_autocmd, state.svg_autocmd_id)
    state.svg_autocmd_id = nil
  end
end

--- Refresh SVG preview (regenerate to temp directory)
function M.refresh_svg_preview()
  local server = require("plantuml.server")

  local info = util.get_puml_file_info()
  if not info then
    return
  end

  local temp_dir = util.ensure_temp_dir()
  if not temp_dir then
    return
  end

  local output_path = temp_dir .. "/" .. info.name .. ".svg"

  executor.run_plantuml(info.fullpath, output_path, "svg", function(success, _)
    if not success then
      return
    end

    local server_port = server.get_port() or 8912
    inject_script(output_path, server_port)
  end)
end

--- Stop SVG preview and cleanup
function M.stop_svg_preview()
  state.svg_preview_active = false
  M.unregister_svg_autocmd()
end

--- Preview SVG in browser
function M.preview_svg()
  local server = require("plantuml.server")

  -- Get file info
  local info = util.get_puml_file_info()
  if not info then
    vim.notify("plantuml.nvim: No PlantUML buffer found", vim.log.levels.ERROR)
    return
  end

  -- Ensure temp directory exists
  local temp_dir = util.ensure_temp_dir()
  if not temp_dir then
    return
  end

  -- Store source buffer for SVG preview
  state.svg_source_bufnr = api.nvim_get_current_buf()

  -- Generate SVG to temp directory
  local output_path = temp_dir .. "/" .. info.name .. ".svg"

  executor.run_plantuml(info.fullpath, output_path, "svg", function(success, _)
    if not success then
      return
    end

    -- Inject auto-refresh script into SVG (only for preview, not for export)
    local server_port = server.get_port() or 8912
    inject_script(output_path, server_port)

    -- Start server if not running
    server.start_server(function(url)
      if not url then
        vim.notify("plantuml.nvim: Failed to start preview server", vim.log.levels.ERROR)
        return
      end

      -- Mark SVG preview as active and register autocmd
      state.svg_preview_active = true
      M.register_svg_autocmd()

      -- Open browser
      local preview_url = url .. "/" .. info.name .. ".svg"
      vim.ui.open(preview_url)
    end)
  end)
end

return M