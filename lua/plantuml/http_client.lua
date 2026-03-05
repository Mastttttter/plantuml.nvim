--- HTTP client module for plantuml.nvim
--- Provides async HTTP communication with the preview server

local M = {}

--- Handle HTTP error with notification
--- @param stderr string Error message from curl
--- @param code number Exit code
--- @param callback function Callback function(false, error_msg)
--- @param silent boolean If true, don't show notification (for retries)
local function handle_error(stderr, code, callback, silent)
  local error_msg = stderr
  if error_msg == "" or not error_msg then
    error_msg = "HTTP request failed with exit code " .. code
  end
  if not silent then
    vim.notify(
      "plantuml.nvim: " .. error_msg,
      vim.log.levels.ERROR
    )
  end
  callback(false, error_msg)
end

--- Build curl command for HTTP POST request
--- @param url string Full URL to send request to
--- @param body string|nil JSON body string (optional)
--- @return table Command arguments array
local function build_curl_cmd(url, body)
  local cmd = {
    "curl",
    "-s",                    -- Silent mode
    "-S",                    -- Show errors
    "-X", "POST",            -- POST method
    "-H", "Content-Type: application/json",
    "-H", "Accept: application/json",
  }

  -- Add body if provided
  if body then
    table.insert(cmd, "-d")
    table.insert(cmd, body)
  end

  -- Add timeout options and URL at the end
  table.insert(cmd, "--connect-timeout")
  table.insert(cmd, "2")     -- 2 second connection timeout
  table.insert(cmd, "--max-time")
  table.insert(cmd, "5")     -- 5 second max request time
  table.insert(cmd, url)

  return cmd
end

--- Send HTTP POST request asynchronously with retry support
--- @param url string Full URL to send request to
--- @param body string|nil JSON body string (optional)
--- @param callback function Callback function(success, error_or_nil)
--- @param retries number Number of retries remaining (default 3)
local function http_post(url, body, callback, retries)
  retries = retries or 3
  local cmd = build_curl_cmd(url, body)

  -- Use vim.system if available (Neovim 0.10+)
  if vim.system then
    vim.system(cmd, { text = true }, function(result)
      if result.code ~= 0 then
        -- Check if it's a connection error and we have retries left
        if retries > 1 and (result.stderr:match("Could not connect") or result.stderr:match("Connection refused")) then
          -- Retry after a short delay
          vim.defer_fn(function()
            http_post(url, body, callback, retries - 1)
          end, 300)
        else
          handle_error(result.stderr, result.code, callback, retries > 1)
        end
      else
        callback(true, nil)
      end
    end)
  else
    -- Fallback for older Neovim versions: use vim.loop.spawn
    local uv = vim.loop
    local stdout = uv.new_pipe()
    local stderr = uv.new_pipe()
    local stderr_data = ""

    local handle
    handle = uv.spawn("curl", {
      args = cmd,
      stdio = { nil, stdout, stderr },
    }, function(code)
      stdout:close()
      stderr:close()
      handle:close()

      if code ~= 0 then
        -- Check if it's a connection error and we have retries left
        if retries > 1 and (stderr_data:match("Could not connect") or stderr_data:match("Connection refused")) then
          -- Retry after a short delay
          vim.defer_fn(function()
            http_post(url, body, callback, retries - 1)
          end, 300)
        else
          vim.schedule(function()
            handle_error(stderr_data, code, callback, retries > 1)
          end)
        end
      else
        vim.schedule(function()
          callback(true, nil)
        end)
      end
    end)

    if not handle then
      vim.notify(
        "plantuml.nvim: Failed to spawn curl process",
        vim.log.levels.ERROR
      )
      callback(false, "Failed to spawn curl process")
      return
    end

    stderr:read_start(function(err, data)
      if data then
        stderr_data = stderr_data .. data
      end
    end)
  end
end

--- Send update notification to preview server
--- @param host string Server host (e.g., "localhost")
--- @param port number Server port (e.g., 8912)
--- @param filename string Diagram filename
--- @param filepath string Full path to the SVG file
--- @param callback function Callback function(success, error_or_nil)
function M.notify_update(host, port, filename, filepath, callback)
  local url = string.format("http://%s:%d/update", host, port)
  local body = string.format(
    '{"filename":"%s","filepath":"%s"}',
    filename,
    filepath
  )

  http_post(url, body, callback, 3)
end

--- Send shutdown notification to preview server
--- @param host string Server host (e.g., "localhost")
--- @param port number Server port (e.g., 8912)
--- @param callback function Callback function(success, error_or_nil)
function M.notify_shutdown(host, port, callback)
  local url = string.format("http://%s:%d/shutdown", host, port)

  http_post(url, nil, callback, 3)
end

return M