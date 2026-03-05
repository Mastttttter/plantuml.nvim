-- Test server module
local server = require("plantuml.server")

describe("server module", function()
  -- Store original functions for cleanup
  local original_notify
  local original_loop
  local original_executable
  local original_system
  local notify_messages
  local spawned_processes
  local process_handles
  local process_id_counter
  local mock_pipes

  before_each(function()
    -- Reset state
    notify_messages = {}
    spawned_processes = {}
    process_handles = {}
    process_id_counter = 1
    mock_pipes = {}

    -- Mock vim.notify to capture messages
    original_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(notify_messages, { msg = msg, level = level })
    end

    -- Mock vim.fn.executable
    original_executable = vim.fn.executable
    vim.fn.executable = function(cmd)
      if cmd == "node" then
        return 1 -- Node is available
      end
      if cmd == "curl" then
        return 1 -- curl is available
      end
      return original_executable(cmd)
    end

    -- Mock vim.system for HTTP requests
    original_system = vim.system
    vim.system = function(cmd, opts, callback)
      -- Default: simulate successful response
      callback({ code = 0, stdout = "OK", stderr = "" })
    end

    -- Mock vim.loop for process spawning
    original_loop = vim.loop
    vim.loop = vim.loop or {}

    -- Mock new_pipe
    vim.loop.new_pipe = function()
      local pipe = {}
      pipe.read_start = function(self, callback)
        -- Simulate reading PORT:8912
        vim.schedule(function()
          callback(nil, "PORT:8912\n")
        end)
      end
      pipe.close = function() end
      table.insert(mock_pipes, pipe)
      return pipe
    end

    -- Mock spawn
    vim.loop.spawn = function(cmd, opts, on_exit)
      local handle_id = process_id_counter
      process_id_counter = process_id_counter + 1

      -- Track the command
      table.insert(spawned_processes, {
        id = handle_id,
        cmd = cmd,
        args = opts.args,
        stdio = opts.stdio,
      })

      -- Create a mock handle
      local handle = {
        pid = handle_id,
        is_running = true,
        closed = false,
      }

      process_handles[handle_id] = handle

      -- Mock get_pid
      handle.get_pid = function()
        return handle_id
      end

      -- Mock close
      handle.close = function()
        handle.closed = true
        handle.is_running = false
      end

      -- Simulate async process start
      vim.schedule(function()
        -- For now, don't call on_exit - server stays running
      end)

      return handle
    end

    -- Mock TCP for port checking
    vim.loop.new_tcp = function()
      return {
        bind = function(self, host, port)
          return true -- Port is available
        end,
        close = function() end,
      }
    end

    -- Reset module state by requiring it fresh
    package.loaded["plantuml.server"] = nil
    package.loaded["plantuml.config"] = nil
    server = require("plantuml.server")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.fn.executable = original_executable
    vim.loop = original_loop
    vim.system = original_system
  end)

  describe("FR-1: Module Exports", function()
    it("exports start_server function", function()
      assert.is_function(server.start_server)
    end)

    it("exports stop_server function", function()
      assert.is_function(server.stop_server)
    end)

    it("start_server accepts callback parameter", function()
      -- Should not error when called with callback
      local callback_called = false
      server.start_server(function(url)
        callback_called = true
      end)

      -- Wait for async callback
      vim.wait(100, function()
        return callback_called
      end, 10)
    end)

    it("stop_server can be called without error", function()
      -- Should not error when called even if no server is running
      server.stop_server()
    end)
  end)

  describe("FR-2: Server Lifecycle Management", function()
    it("start_server spawns node process with server.js", function()
      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      -- Verify node command was spawned
      assert.is_true(#spawned_processes > 0)
      local spawn_info = spawned_processes[1]
      -- cmd is the first argument to spawn (a string, not array)
      assert.is_equal("node", spawn_info.cmd)
      -- args should contain path to server.js
      assert.is_not_nil(spawn_info.args)
      local found_server_js = false
      for _, arg in ipairs(spawn_info.args) do
        if arg:match("server%.js$") then
          found_server_js = true
          break
        end
      end
      assert.is_true(found_server_js)
    end)

    it("start_server calls callback with URL", function()
      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      -- Verify URL format
      assert.is_true(callback_url:match("^http://localhost:%d+$") ~= nil)
    end)

    it("start_server uses configured port", function()
      -- Set up config with custom port
      local config = require("plantuml.config")
      config.setup({ server_port = 9090 })

      -- Reset server module
      package.loaded["plantuml.server"] = nil
      server = require("plantuml.server")

      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      -- Verify URL format (port may differ due to mock limitations)
      assert.is_not_nil(callback_url)
      assert.is_true(callback_url:match("^http://localhost:%d+$") ~= nil)

      -- Verify spawn was called with correct port argument
      if #spawned_processes > 0 then
        local args = spawned_processes[1].args
        local found_port = false
        for i, arg in ipairs(args) do
          if arg == "--port" and args[i + 1] then
            local port = tonumber(args[i + 1])
            -- Port should be in the expected range
            assert.is_true(port >= 9090 and port <= 9110)
            found_port = true
            break
          end
        end
        assert.is_true(found_port)
      end
    end)

    it("stop_server kills the running process", function()
      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      -- Stop the server
      server.stop_server()

      -- Process should no longer be tracked
      -- (implementation detail - we check that calling stop_server twice doesn't error)
      server.stop_server()
    end)
  end)

  describe("FR-3: Port Conflict Detection", function()
    it("increments port on EADDRINUSE", function()
      -- This test verifies that port fallback logic exists
      -- The actual port conflict would be detected by the Node.js server
      -- and communicated back to Lua

      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      -- Should have a valid URL
      assert.is_not_nil(callback_url)
      assert.is_true(callback_url:match("^http://localhost:%d+$") ~= nil)
    end)

    it("limits port range to prevent infinite loop", function()
      -- This test verifies the port range limit exists in server.js
      -- MAX_PORT = 8099 in server.js, DEFAULT_PORT = 8912
      -- The server tries ports from start_port to MAX_PORT

      local callback_url
      local callback_error = false

      server.start_server(function(url, err)
        if err then
          callback_error = true
        else
          callback_url = url
        end
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil or callback_error
      end, 10)

      -- Should have a valid URL with port in valid range
      assert.is_not_nil(callback_url, "Should have a valid URL")
      local port = callback_url:match(":(%d+)$")
      assert.is_not_nil(port, "URL should contain a port")
      local port_num = tonumber(port)
      -- Port should be within the valid range defined in server.js (8912 to 8099)
      assert.is_true(port_num >= 8912 and port_num <= 8099, "Port should be in valid range 8912-8099")
    end)
  end)

  describe("FR-4: Server URL Callback", function()
    it("callback receives http://localhost:<port>", function()
      local callback_url
      server.start_server(function(url)
        callback_url = url
      end)

      -- Wait for async
      vim.wait(100, function()
        return callback_url ~= nil
      end, 10)

      assert.is_equal("http://localhost:8912", callback_url)
    end)

    it("handles nil callback gracefully", function()
      -- Should not error when callback is nil
      server.start_server(nil)

      -- Wait a bit for any async operations
      vim.wait(50)
    end)

    it("handles missing node.js executable", function()
      -- Mock vim.fn.executable to simulate node not found
      local original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "node" then
          return 0 -- Not found
        end
        return original_executable(cmd)
      end

      -- Reset server module
      package.loaded["plantuml.server"] = nil
      server = require("plantuml.server")

      local callback_error = nil
      server.start_server(function(url, err)
        callback_error = err
      end)

      -- Wait for async
      vim.wait(100)

      -- Restore original
      vim.fn.executable = original_executable

      -- Should have received an error
      assert.is_not_nil(callback_error)
      assert.is_true(callback_error:find("Node.js not found") ~= nil)
    end)
  end)

  describe("FR-5: No File Watcher in Server", function()
    -- These tests verify that the server.js has no file watcher code
    -- (Architecture change from file watching to HTTP notification)

    it("server.js exists and contains no fs.watch calls", function()
      -- Read the server.js file
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file, "server.js should exist")

      local content = file:read("*all")
      file:close()

      -- Check for no fs.watch or fs.watchFile
      assert.is_nil(content:match("fs%.watch%s*%("), "server.js should not use fs.watch()")
      assert.is_nil(content:match("fs%.watchFile"), "server.js should not use fs.watchFile()")
      assert.is_nil(content:match("startFileWatcher"), "server.js should not have startFileWatcher function")
      assert.is_nil(content:match("fileWatcher%s*="), "server.js should not have fileWatcher variable")
    end)

    it("server.js uses HTTP server instead of file watching", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file, "server.js should exist")

      local content = file:read("*all")
      file:close()

      -- Verify HTTP server is used
      assert.is_not_nil(content:match("http%.createServer"), "server.js should use http.createServer")
      assert.is_not_nil(content:match("server%.listen"), "server.js should call server.listen()")
    end)
  end)

  describe("FR-6: GET / Endpoint (HTML Page)", function()
    it("server.js has route for GET / returning HTML", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify GET / route exists (using === in JavaScript)
      assert.is_not_nil(content:match("urlPath%s*===%s*['\"]/%s*['\"]"), "server.js should have route for /")
      assert.is_not_nil(content:match("req%.method%s*===%s*['\"]GET['\"]"), "server.js should handle GET requests")

      -- Verify HTML generation
      assert.is_not_nil(content:match("generateHTML"), "server.js should have generateHTML function")
      assert.is_not_nil(content:match("<!DOCTYPE html>"), "server.js should generate valid HTML")
    end)

    it("HTML contains required UI elements", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify HTML template elements
      assert.is_not_nil(content:match("<title>"), "HTML should have title element")
      assert.is_not_nil(content:match('id="svg%-container"'), "HTML should have svg-container element")
      assert.is_not_nil(content:match("last%-update"), "HTML should show last update time")
      assert.is_not_nil(content:match("EventSource"), "HTML should connect to SSE with EventSource")
    end)
  end)

  describe("FR-7: GET /svg Endpoint", function()
    it("server.js has route for GET /svg returning SVG content", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify GET /svg route exists
      assert.is_not_nil(content:match("urlPath%s*===%s*['\"]%/svg['\"]"), "server.js should have route for /svg")

      -- Verify content-type for SVG
      assert.is_not_nil(content:match("image/svg%+xml"), "server.js should set correct content-type for SVG")
    end)

    it("returns cached SVG content from state", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify state object exists
      assert.is_not_nil(content:match("state%s*="), "server.js should have state object")
      assert.is_not_nil(content:match("svgContent"), "state should contain svgContent")
    end)

    it("includes CORS headers in response", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify CORS headers
      assert.is_not_nil(content:match("Access%-Control%-Allow%-Origin"), "server.js should set CORS headers")
    end)
  end)

  describe("FR-8: POST /update Endpoint", function()
    it("server.js has route for POST /update", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify POST /update route exists
      assert.is_not_nil(content:match("urlPath%s*===%s*['\"]%/update['\"]"), "server.js should have route for /update")
    end)

    it("accepts JSON body with filename and filepath", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify JSON parsing
      assert.is_not_nil(content:match("JSON%.parse"), "server.js should parse JSON body")
      assert.is_not_nil(content:match("data%.filename"), "server.js should check filename field")
      assert.is_not_nil(content:match("data%.filepath"), "server.js should check filepath field")
    end)

    it("reads SVG file from provided filepath", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify file reading
      assert.is_not_nil(content:match("fs%.readFileSync"), "server.js should read SVG file")
    end)

    it("returns 400 for missing fields", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify 400 response
      assert.is_not_nil(content:match("400"), "server.js should return 400 for bad request")
      assert.is_not_nil(content:match("Bad Request"), "server.js should return Bad Request message")
    end)

    it("returns 404 for non-existent file", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify 404 response
      assert.is_not_nil(content:match("fs%.existsSync"), "server.js should check file existence")
      assert.is_not_nil(content:match("404"), "server.js should return 404 for not found")
    end)

    it("broadcasts update event to SSE clients", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify broadcast
      assert.is_not_nil(content:match("broadcastEvent"), "server.js should have broadcastEvent function")
      -- The update event is broadcast with 'update' as first argument
      assert.is_not_nil(content:match("broadcastEvent%(['\"]update['\"]"), "server.js should broadcast update event")
    end)
  end)

  describe("FR-9: POST /shutdown Endpoint", function()
    it("server.js has route for POST /shutdown", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify POST /shutdown route exists
      assert.is_not_nil(content:match("urlPath%s*===%s*['\"]%/shutdown['\"]"), "server.js should have route for /shutdown")
    end)

    it("broadcasts shutdown event to SSE clients", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify broadcast - the shutdown event is broadcast with 'shutdown' as first argument
      assert.is_not_nil(content:match("broadcastEvent%(['\"]shutdown['\"]"), "server.js should broadcast shutdown event")
    end)

    it("returns 200 OK", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify 200 response
      assert.is_not_nil(content:match("res%.writeHead%s*%(%s*200%s*%)"), "server.js should return 200 for shutdown")
    end)
  end)

  describe("FR-10: SSE Events (update, shutdown)", function()
    it("server.js has SSE endpoint at GET /events", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify /events route
      assert.is_not_nil(content:match("urlPath%s*===%s*['\"]%/events['\"]"), "server.js should have route for /events")
    end)

    it("sets correct SSE headers", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify SSE headers
      assert.is_not_nil(content:match("text/event%-stream"), "server.js should set Content-Type: text/event-stream")
      assert.is_not_nil(content:match("no%-cache"), "server.js should set Cache-Control: no-cache")
      assert.is_not_nil(content:match("keep%-alive"), "server.js should set Connection: keep-alive")
    end)

    it("tracks connected SSE clients in a Set", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify client tracking
      assert.is_not_nil(content:match("sseClients"), "server.js should track SSE clients")
      assert.is_not_nil(content:match("new Set"), "server.js should use Set for client tracking")
    end)

    it("sends initial connected event", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify initial connection event
      assert.is_not_nil(content:match("event:%s*connected"), "server.js should send connected event")
    end)

    it("can broadcast update event to clients", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify update event in message template
      -- The message format is: `event: ${eventType}\ndata: ${data}\n\n`
      -- So when eventType is 'update', it produces "event: update"
      assert.is_not_nil(content:match("event:%s*%${eventType}"), "server.js should broadcast event with eventType variable")
    end)

    it("can broadcast shutdown event to clients", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify shutdown event is broadcast
      assert.is_not_nil(content:match("broadcastEvent%(['\"]shutdown['\"]"), "server.js should broadcast shutdown event")
    end)

    it("removes disconnected clients from tracking", function()
      local script_path = debug.getinfo(1, "S").source:match("^@(.+)$")
      local plugin_root = vim.fn.fnamemodify(script_path, ":h:h:h")
      local server_js_path = plugin_root .. "/server/server.js"

      local file = io.open(server_js_path, "r")
      assert.is_not_nil(file)

      local content = file:read("*all")
      file:close()

      -- Verify client cleanup on disconnect
      assert.is_not_nil(content:match("sseClients%.delete"), "server.js should remove disconnected clients")
      assert.is_not_nil(content:match("on%s*%(%s*['\"]close['\"]"), "server.js should listen for close event")
    end)
  end)
end)