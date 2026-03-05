-- Test http_client module
local http_client = require("plantuml.http_client")

describe("http_client module", function()
  -- Store original functions for cleanup
  local original_system
  local original_notify
  local notify_messages

  before_each(function()
    -- Reset notify messages tracker
    notify_messages = {}

    -- Mock vim.notify to capture messages
    original_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(notify_messages, { msg = msg, level = level })
    end

    -- Mock vim.system to capture calls
    original_system = vim.system

    -- Reset module state
    package.loaded["plantuml.http_client"] = nil
    http_client = require("plantuml.http_client")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.system = original_system
  end)

  describe("FR-1: notify_update function", function()
    it("sends HTTP POST request to /update endpoint with JSON body", function()
      local captured_cmd = nil
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        captured_opts = opts
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      local callback_called = false
      local callback_success = nil
      local callback_error = nil

      http_client.notify_update("localhost", 8912, "diagram.puml", "/tmp/test.svg", function(success, err)
        callback_called = true
        callback_success = success
        callback_error = err
      end)

      assert.is_true(callback_called)
      assert.is_true(callback_success)
      assert.is_nil(callback_error)

      -- Verify curl command is executed
      assert.is_not_nil(captured_cmd)
      assert.are.equal("curl", captured_cmd[1])

      -- Verify URL contains host:port/update
      local url_found = false
      for _, arg in ipairs(captured_cmd) do
        if arg:match("localhost:8912/update") then
          url_found = true
        end
      end
      assert.is_true(url_found, "URL should contain localhost:8912/update")

      -- Verify JSON body contains filename and filepath
      local json_found = false
      for i, arg in ipairs(captured_cmd) do
        if arg == "-d" or arg == "--data" then
          local data = captured_cmd[i + 1]
          if data and data:match('"filename"') and data:match('"filepath"') then
            json_found = true
          end
        end
      end
      assert.is_true(json_found, "should send JSON body with filename and filepath")
    end)

    it("handles connection error with vim.notify ERROR level", function()
      vim.system = function(cmd, opts, callback)
        -- Simulate curl connection refused (exit code 7)
        callback({ code = 7, stdout = "", stderr = "curl: (7) Failed to connect to localhost port 8912" })
      end

      local callback_called = false
      local callback_success = nil
      local callback_error = nil

      http_client.notify_update("localhost", 8912, "diagram.puml", "/tmp/test.svg", function(success, err)
        callback_called = true
        callback_success = success
        callback_error = err
      end)

      assert.is_true(callback_called)
      assert.is_false(callback_success)
      assert.is_not_nil(callback_error)

      -- Check that vim.notify was called with ERROR level
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      assert.is_true(found_error, "should have called vim.notify with ERROR level")
    end)

    it("calls callback after request completes", function()
      local callback_called = false
      local callback_args = nil

      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      http_client.notify_update("localhost", 8912, "diagram.puml", "/tmp/test.svg", function(success, err)
        callback_called = true
        callback_args = { success = success, err = err }
      end)

      assert.is_true(callback_called)
      assert.is_true(callback_args.success)
      assert.is_nil(callback_args.err)
    end)

    it("sets Content-Type header to application/json", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      http_client.notify_update("localhost", 8912, "diagram.puml", "/tmp/test.svg", function() end)

      -- Verify Content-Type header is set
      local has_content_type = false
      for i, arg in ipairs(captured_cmd) do
        if arg == "-H" or arg == "--header" then
          local header = captured_cmd[i + 1]
          if header and header:match("Content%-Type:%s*application/json") then
            has_content_type = true
          end
        end
      end
      assert.is_true(has_content_type, "should set Content-Type: application/json header")
    end)
  end)

  describe("FR-2: notify_shutdown function", function()
    it("sends HTTP POST request to /shutdown endpoint", function()
      local captured_cmd = nil
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        captured_opts = opts
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      local callback_called = false
      local callback_success = nil

      http_client.notify_shutdown("localhost", 8912, function(success, err)
        callback_called = true
        callback_success = success
      end)

      assert.is_true(callback_called)
      assert.is_true(callback_success)

      -- Verify curl command is executed
      assert.is_not_nil(captured_cmd)
      assert.are.equal("curl", captured_cmd[1])

      -- Verify URL contains host:port/shutdown
      local url_found = false
      for _, arg in ipairs(captured_cmd) do
        if arg:match("localhost:8912/shutdown") then
          url_found = true
        end
      end
      assert.is_true(url_found, "URL should contain localhost:8912/shutdown")
    end)

    it("handles connection error with vim.notify ERROR level", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 7, stdout = "", stderr = "curl: (7) Failed to connect" })
      end

      local callback_success = nil
      local callback_error = nil

      http_client.notify_shutdown("localhost", 8912, function(success, err)
        callback_success = success
        callback_error = err
      end)

      assert.is_false(callback_success)
      assert.is_not_nil(callback_error)

      -- Check vim.notify was called with ERROR
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
          break
        end
      end
      assert.is_true(found_error)
    end)

    it("calls callback after request completes", function()
      local callback_called = false
      local callback_args = nil

      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      http_client.notify_shutdown("localhost", 8912, function(success, err)
        callback_called = true
        callback_args = { success = success, err = err }
      end)

      assert.is_true(callback_called)
      assert.is_true(callback_args.success)
      assert.is_nil(callback_args.err)
    end)
  end)

  describe("FR-3: HTTP error handling", function()
    it("handles connection refused (curl exit code 7)", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 7, stdout = "", stderr = "curl: (7) Failed to connect" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function(success, err)
        assert.is_false(success)
        assert.is_not_nil(err)
      end)

      -- Verify error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error)
    end)

    it("handles timeout (curl exit code 28)", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 28, stdout = "", stderr = "curl: (28) Connection timed out" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function(success, err)
        assert.is_false(success)
        assert.is_not_nil(err)
      end)

      -- Verify error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error)
    end)

    it("handles HTTP 404 response", function()
      vim.system = function(cmd, opts, callback)
        -- curl with --fail flag returns exit code 22 for HTTP errors
        callback({ code = 22, stdout = "", stderr = "curl: (22) HTTP returned 404" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function(success, err)
        assert.is_false(success)
        assert.is_not_nil(err)
      end)

      -- Verify error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error)
    end)

    it("handles HTTP 500 response", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 22, stdout = "", stderr = "curl: (22) HTTP returned 500" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function(success, err)
        assert.is_false(success)
        assert.is_not_nil(err)
      end)

      -- Verify error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error)
    end)
  end)

  describe("FR-4: Module exports and vim.system usage", function()
    it("exports notify_update function", function()
      assert.is_not_nil(http_client.notify_update)
      assert.is_true(type(http_client.notify_update) == "function")
    end)

    it("exports notify_shutdown function", function()
      assert.is_not_nil(http_client.notify_shutdown)
      assert.is_true(type(http_client.notify_shutdown) == "function")
    end)

    it("uses vim.system with correct arguments", function()
      local captured_cmd = nil
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        captured_opts = opts
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function() end)

      assert.is_not_nil(captured_cmd)
      assert.is_not_nil(captured_opts)
      assert.is_true(captured_opts.text, "vim.system should be called with text = true")
    end)

    it("uses curl command with POST method", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "OK", stderr = "" })
      end

      http_client.notify_update("localhost", 8912, "test.puml", "/tmp/test.svg", function() end)

      assert.is_not_nil(captured_cmd)
      assert.are.equal("curl", captured_cmd[1])

      -- Verify POST method is used
      local has_post = false
      for i, arg in ipairs(captured_cmd) do
        if arg == "-X" or arg == "--request" then
          if captured_cmd[i + 1] == "POST" then
            has_post = true
          end
        end
      end
      assert.is_true(has_post, "should use POST method")
    end)
  end)
end)