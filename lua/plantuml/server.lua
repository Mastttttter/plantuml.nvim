--- Server module for plantuml.nvim
--- Manages Node.js static file server lifecycle for SVG preview

local M = {}

local uv = vim.loop
local config = require("plantuml.config")
local util = require("plantuml.util")

-- Server state (singleton)
local server_state = {
  handle = nil,
  pid = nil,
  port = nil,
  url = nil,
  running = false,
}

--- Get the path to server.js
---@return string Path to server.js file
local function get_server_js_path()
  -- Get the script path (this file's directory)
  local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
  if not script_path then
    return "server/server.js"
  end

  -- Navigate from lua/plantuml/ to server/
  local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
  return plugin_root .. "/server/server.js"
end

--- Check if node is available
---@return boolean true if node executable is found
local function is_node_available()
  return vim.fn.executable("node") == 1
end

--- Check if a port is in use (simple check by attempting to connect)
---@param port number Port number to check
---@return boolean true if port appears to be in use
local function is_port_in_use(port)
  -- Simple check: try to bind to the port
  -- If bind fails, something is likely using it
  local handle = uv.new_tcp()
  local ok = handle:bind("127.0.0.1", port)
  handle:close()
  return not ok
end

--- Kill the running server process
local function kill_server()
  if server_state.handle then
    -- Send SIGTERM to the process
    uv.kill(server_state.pid, 15) -- 15 = SIGTERM
    server_state.handle = nil
    server_state.pid = nil
    server_state.running = false
  end
end

--- Start the Node.js server
---@param callback function|nil Callback function(url) called when server starts
---@return nil
function M.start_server(callback)
  -- Check if server is already running
  if server_state.running and server_state.url then
    if callback then
      callback(server_state.url)
    end
    return
  end

  -- Check if node is available
  if not is_node_available() then
    vim.notify(
      "plantuml.nvim: Node.js not found. Please install Node.js to use preview server.",
      vim.log.levels.ERROR
    )
    if callback then
      callback(nil, "Node.js not found")
    end
    return
  end

  -- Ensure temp directory exists
  local temp_dir = util.ensure_temp_dir()
  if not temp_dir then
    vim.notify(
      "plantuml.nvim: Failed to create temp directory for preview.",
      vim.log.levels.ERROR
    )
    if callback then
      callback(nil, "Failed to create temp directory")
    end
    return
  end

  -- Get configuration
  local cfg = config.get()
  local start_port = cfg.server_port or 8912
  local max_port = start_port + 20 -- Allow up to 20 port increments

  -- Get server.js path
  local server_js = get_server_js_path()

  -- Find an available port (skip check if port is 0, let OS assign)
  local port = start_port
  for p = start_port, max_port do
    if not is_port_in_use(p) then
      port = p
      break
    end
    if p == max_port then
      vim.notify(
        "plantuml.nvim: No available port found in range " .. start_port .. "-" .. max_port,
        vim.log.levels.ERROR
      )
      if callback then
        callback(nil, "No available port")
      end
      return
    end
  end

  -- Spawn the Node.js server
  local args = { server_js, "--port", tostring(port) }

  -- Create pipes for stdout and stderr
  local stdout_pipe = uv.new_pipe()
  local stderr_pipe = uv.new_pipe()

  server_state.handle = uv.spawn("node", {
    args = args,
    stdio = { nil, stdout_pipe, stderr_pipe },
    hide = true,
  }, function(code, signal)
    -- Process exited
    server_state.handle = nil
    server_state.pid = nil
    server_state.running = false

    if code ~= 0 and code ~= nil then
      vim.schedule(function()
        vim.notify(
          "plantuml.nvim: Server process exited with code " .. code,
          vim.log.levels.WARN
        )
      end)
    end
  end)

  if not server_state.handle then
    vim.notify(
      "plantuml.nvim: Failed to start Node.js server.",
      vim.log.levels.ERROR
    )
    if callback then
      callback(nil, "Failed to spawn server")
    end
    return
  end

  server_state.pid = server_state.handle:get_pid()
  server_state.port = port
  server_state.url = "http://localhost:" .. port
  server_state.running = true

  -- Track if callback has been called
  local callback_called = false
  local callback_timeout = nil

  local function call_callback(url)
    if callback_called then return end
    callback_called = true
    if callback_timeout then
      vim.fn.timer_stop(callback_timeout)
      callback_timeout = nil
    end
    if callback then
      callback(url)
    end
  end

  -- Read stdout for PORT:XXXX output
  stdout_pipe:read_start(function(err, data)
    if err or not data then
      return
    end

    -- Check for PORT:XXXX output (server successfully started)
    local actual_port = data:match("PORT:(%d+)")
    if actual_port then
      server_state.port = tonumber(actual_port)
      server_state.url = "http://localhost:" .. actual_port
      -- Call callback with actual port
      call_callback(server_state.url)
    end

    -- Check for server started message
    if data:match("Server started on port") then
      call_callback(server_state.url)
    end
  end)

  -- Read stderr for errors
  stderr_pipe:read_start(function(err, data)
    if err or not data then
      return
    end
    vim.schedule(function()
      vim.notify(
        "plantuml.nvim: Server error: " .. data,
        vim.log.levels.ERROR
      )
    end)
    -- If server failed to start, call callback with nil
    if data:match("EADDRINUSE") or data:match("Failed to start server") then
      call_callback(nil)
    end
  end)

  -- Set a timeout in case server never outputs PORT
  callback_timeout = vim.fn.timer_start(2000, function()
    if not callback_called then
      vim.schedule(function()
        vim.notify(
          "plantuml.nvim: Server startup timeout",
          vim.log.levels.WARN
        )
      end)
      call_callback(server_state.url)
    end
  end)
end

--- Stop the running server
---@return nil
function M.stop_server()
  kill_server()
  server_state.url = nil
  server_state.port = nil
end

--- Check if server is running
---@return boolean true if server is running
function M.is_running()
  return server_state.running
end

--- Get the current server URL
---@return string|nil Server URL or nil if not running
function M.get_url()
  return server_state.url
end

--- Get the current server port
---@return number|nil Server port or nil if not running
function M.get_port()
  return server_state.port
end

return M
