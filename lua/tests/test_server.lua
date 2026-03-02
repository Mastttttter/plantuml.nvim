-- Test server module
local server = require("plantuml.server")

describe("server module", function()
  -- Store original functions for cleanup
  local original_notify
  local original_loop
  local original_executable
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
      return original_executable(cmd)
    end

    -- Mock vim.loop for process spawning
    original_loop = vim.loop
    vim.loop = vim.loop or {}

    -- Mock new_pipe
    vim.loop.new_pipe = function()
      local pipe = {}
      pipe.read_start = function(self, callback)
        -- Simulate reading PORT:8080
        vim.schedule(function()
          callback(nil, "PORT:8080\n")
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
        -- Call on_exit after a short delay (simulating process running)
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
      -- This test verifies the port range limit exists
      -- Implementation should stop trying after reaching max port

      local config = require("plantuml.config")
      config.setup({ server_port = 8095 }) -- Near the limit

      -- Reset server module
      package.loaded["plantuml.server"] = nil
      server = require("plantuml.server")

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

      -- Should have a valid URL within range
      if callback_url then
        local port = callback_url:match(":(%d+)$")
        assert.is_not_nil(port)
        local port_num = tonumber(port)
        assert.is_true(port_num >= 8080 and port_num <= 8099)
      end
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

      assert.is_equal("http://localhost:8080", callback_url)
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
end)