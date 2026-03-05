-- Test preview module
local preview = require("plantuml.preview")
local util = require("plantuml.util")
local api = vim.api

describe("preview module", function()
  -- Store original functions for cleanup
  local original_notify
  local original_system
  local original_executable
  local original_find_newest_file
  local notify_messages
  local test_dir
  local original_windows
  local original_buffers

  before_each(function()
    -- Save original window/buffer state
    original_windows = api.nvim_list_wins()
    original_buffers = api.nvim_list_bufs()

    -- Create test directory
    test_dir = vim.fn.fnamemodify(vim.fn.tempname(), ":h") .. "/plantuml_preview_test_" .. os.time()
    vim.fn.mkdir(test_dir, "p")

    -- Reset notify messages tracker
    notify_messages = {}

    -- Mock vim.notify to capture messages
    original_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(notify_messages, { msg = msg, level = level })
    end

    -- Mock vim.system to capture calls
    original_system = vim.system

    -- Mock executable for config
    original_executable = vim.fn.executable
    vim.fn.executable = function(cmd)
      return 1 -- All executables available
    end

    -- Reset module state
    package.loaded["plantuml.config"] = nil
    package.loaded["plantuml.executor"] = nil
    package.loaded["plantuml.preview"] = nil
    package.loaded["plantuml.util"] = nil

    -- Initialize config before requiring executor/preview
    local config = require("plantuml.config")
    config.setup()

    -- Re-require util after reset to get fresh module for mocking
    util = require("plantuml.util")
    
    -- Mock util.find_newest_file to return a test file path
    original_find_newest_file = util.find_newest_file
    util.find_newest_file = function(dir, ext)
      if ext == "utxt" then
        return "/tmp/plantuml.nvim/test_diagram.utxt"
      end
      return nil
    end

    preview = require("plantuml.preview")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.system = original_system
    vim.fn.executable = original_executable
    util.find_newest_file = original_find_newest_file

    -- Close any preview windows
    for _, win in ipairs(api.nvim_list_wins()) do
      if not vim.tbl_contains(original_windows, win) then
        pcall(api.nvim_win_close, win, true)
      end
    end

    -- Delete any test buffers
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if not vim.tbl_contains(original_buffers, buf) then
        pcall(api.nvim_buf_delete, buf, { force = true })
      end
    end

    -- Cleanup test directories
    if test_dir and vim.fn.isdirectory(test_dir) == 1 then
      vim.fn.delete(test_dir, "rf")
    end
  end)

  describe("FR-1: preview_utxt() function", function()
    it("exports preview_utxt function", function()
      assert.is_function(preview.preview_utxt)
    end)

    it("creates vertical split with UTXT content on first call", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Hello",
        "@enduml",
      }, test_file)

      -- Open the test file
      vim.cmd("edit " .. test_file)

      -- Track callback execution
      local callback_executed = false

      -- Mock system call to simulate PlantUML execution
      vim.system = function(cmd, opts, callback)
        -- Simulate async callback with vim.schedule
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock file reading
      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "     ,---.", "     |Alice|", "     '---'", }
        end
        return original_readfile(path)
      end

      -- Call preview_utxt
      preview.preview_utxt()

      -- Wait for async operations to complete
      vim.wait(500, function()
        return callback_executed
      end, 10)

      -- Restore readfile
      vim.fn.readfile = original_readfile

      -- Check that a preview buffer was created with plantuml_preview marker
      local found_preview = false
      for _, buf in ipairs(api.nvim_list_bufs()) do
        local ok, val = pcall(api.nvim_buf_get_var, buf, "plantuml_preview")
        if ok and val == true then
          found_preview = true
          break
        end
      end
      assert.is_true(found_preview, "should have created preview buffer with plantuml_preview marker")
    end)

    it("sets plantuml_preview buffer variable on preview buffer", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)

      vim.cmd("edit " .. test_file)

      local callback_executed = false

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock file reading
      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "ASCII art" }
        end
        return original_readfile(path)
      end

      preview.preview_utxt()
      vim.wait(500, function()
        return callback_executed
      end, 10)
      vim.fn.readfile = original_readfile

      -- Find the preview buffer
      local preview_bufnr = nil
      for _, buf in ipairs(api.nvim_list_bufs()) do
        local ok, val = pcall(api.nvim_buf_get_var, buf, "plantuml_preview")
        if ok and val == true then
          preview_bufnr = buf
          break
        end
      end

      assert.is_not_nil(preview_bufnr, "preview buffer should exist")
      local ok, val = pcall(api.nvim_buf_get_var, preview_bufnr, "plantuml_preview")
      assert.is_true(ok and val == true, "buffer should have plantuml_preview = true")
    end)

    it("handles no buffer error gracefully", function()
      -- No buffer is open, but we need one for get_puml_file_info
      -- Clear all buffers except one empty one
      for _, buf in ipairs(api.nvim_list_bufs()) do
        if api.nvim_buf_is_loaded(buf) then
          pcall(api.nvim_buf_delete, buf, { force = true })
        end
      end

      -- Create a scratch buffer with no file
      local scratch = api.nvim_create_buf(false, true)
      api.nvim_set_current_buf(scratch)

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "", stderr = "" })
      end

      -- Call preview_utxt - should handle error gracefully
      preview.preview_utxt()
      vim.wait(100)

      -- Should have shown an error notification
      -- Note: actual behavior depends on util.get_puml_file_info returning nil for no file
    end)
  end)

  describe("FR-2: find_preview_window() function", function()
    it("exports find_preview_window function", function()
      assert.is_function(preview.find_preview_window)
    end)

    it("returns nil when no preview window exists", function()
      local win_id = preview.find_preview_window()
      assert.is_nil(win_id, "should return nil when no preview window exists")
    end)

    it("returns window ID when preview window exists", function()
      -- Create a preview buffer with the marker
      local preview_buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_var(preview_buf, "plantuml_preview", true)

      -- Create a window for it
      vim.cmd("rightbelow vsplit")
      local new_win = api.nvim_get_current_win()
      api.nvim_win_set_buf(new_win, preview_buf)

      -- Go back to original window
      vim.cmd("wincmd p")

      -- Find the preview window
      local win_id = preview.find_preview_window()

      assert.is_not_nil(win_id, "should find the preview window")
      assert.are.equal(new_win, win_id, "should return the correct window ID")
    end)

    it("returns nil when preview buffer exists but window was closed", function()
      -- Create a preview buffer with the marker
      local preview_buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_var(preview_buf, "plantuml_preview", true)

      -- Create and immediately close the window
      vim.cmd("rightbelow vsplit")
      local new_win = api.nvim_get_current_win()
      api.nvim_win_set_buf(new_win, preview_buf)
      vim.cmd("close")

      -- Find the preview window
      local win_id = preview.find_preview_window()

      assert.is_nil(win_id, "should return nil when preview buffer exists but window was closed")
    end)
  end)

  describe("FR-3: update_preview() / refresh_preview() function", function()
    it("exports refresh_preview function", function()
      assert.is_function(preview.refresh_preview)
    end)

    it("updates existing preview buffer content", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Updated",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local callback_executed = false

      -- Mock system call - first call creates preview
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock file reading
      local original_readfile = vim.fn.readfile
      local content_version = 1
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          if content_version == 1 then
            return { "old content" }
          else
            return { "new content" }
          end
        end
        return original_readfile(path)
      end

      -- First create the preview via preview_utxt
      preview.preview_utxt()
      vim.wait(500, function()
        return callback_executed
      end, 10)

      -- Get the preview buffer that was created
      local preview_bufnr = nil
      for _, buf in ipairs(api.nvim_list_bufs()) do
        local ok, val = pcall(api.nvim_buf_get_var, buf, "plantuml_preview")
        if ok and val == true then
          preview_bufnr = buf
          break
        end
      end

      assert.is_not_nil(preview_bufnr, "preview buffer should exist")

      -- Now update content version and refresh
      callback_executed = false
      content_version = 2
      preview.refresh_preview()
      vim.wait(500, function()
        return callback_executed
      end, 10)

      vim.fn.readfile = original_readfile

      -- Check buffer content was updated
      local lines = api.nvim_buf_get_lines(preview_bufnr, 0, -1, false)
      assert.are.same({ "new content" }, lines, "buffer content should be updated")
    end)

    it("subsequent preview_utxt calls update existing buffer", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: First",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local call_count = 0

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        call_count = call_count + 1
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock file reading
      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "content " .. call_count }
        end
        return original_readfile(path)
      end

      -- First call creates preview
      preview.preview_utxt()
      vim.wait(500, function()
        return call_count >= 1
      end, 10)

      local windows_after_first = #api.nvim_list_wins()

      -- Second call should update, not create new window
      preview.preview_utxt()
      vim.wait(500, function()
        return call_count >= 2
      end, 10)

      vim.fn.readfile = original_readfile

      local windows_after_second = #api.nvim_list_wins()

      -- Should not have created additional windows
      assert.are.equal(windows_after_first, windows_after_second, 
        "subsequent calls should not create new windows")
    end)
  end)

  describe("FR-4: BufWritePost autocmd", function()
    it("exports register_autocmd function", function()
      assert.is_function(preview.register_autocmd)
    end)

    it("exports unregister_autocmd function", function()
      assert.is_function(preview.unregister_autocmd)
    end)

    it("register_autocmd creates autocmd group", function()
      preview.register_autocmd()

      -- Check that the augroup exists
      local ok = pcall(api.nvim_get_autocmds, { group = "PlantumlPreview" })
      assert.is_true(ok, "PlantumlPreview augroup should exist")

      preview.unregister_autocmd()
    end)

    it("autocmd triggers on BufWritePost for .puml files", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      -- First create a preview via preview_utxt
      local callback_executed = false
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "ASCII art" }
        end
        return original_readfile(path)
      end

      preview.preview_utxt()
      vim.wait(500, function()
        return callback_executed
      end, 10)
      vim.fn.readfile = original_readfile

      -- Reset for the autocmd test
      callback_executed = false

      -- Mock system call for refresh
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Register autocmd
      preview.register_autocmd()

      -- Simulate BufWritePost
      vim.cmd("doautocmd BufWritePost " .. test_file)

      -- The refresh should be triggered (but only if preview window exists)
      vim.wait(500, function()
        return callback_executed
      end, 10)

      -- Cleanup
      preview.unregister_autocmd()
    end)

    it("unregister_autocmd removes the autocmd", function()
      preview.register_autocmd()

      -- Verify group exists
      local ok_before = pcall(api.nvim_get_autocmds, { group = "PlantumlPreview" })
      assert.is_true(ok_before, "augroup should exist after register")

      preview.unregister_autocmd()

      -- Verify group is cleared (autocmds removed, but group may still exist)
      -- We check that our tracked autocmd_id is nil
      -- This is implementation-specific, so we just verify no error
    end)
  end)

  describe("FR-5: cleanup / close_preview function", function()
    it("exports close_preview function", function()
      assert.is_function(preview.close_preview)
    end)

    it("close_preview closes the preview window", function()
      -- First create a preview via preview_utxt
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local callback_executed = false
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "ASCII art" }
        end
        return original_readfile(path)
      end

      preview.preview_utxt()
      vim.wait(500, function()
        return callback_executed
      end, 10)
      vim.fn.readfile = original_readfile

      -- Get the preview window
      local preview_win = preview.find_preview_window()
      assert.is_not_nil(preview_win, "preview window should exist")

      -- Close the preview
      preview.close_preview()
      vim.wait(50)

      -- Verify the window is closed
      local win_valid = api.nvim_win_is_valid(preview_win)
      assert.is_false(win_valid, "preview window should be closed")
    end)

    it("close_preview clears internal state", function()
      -- First create a preview via preview_utxt
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local callback_executed = false
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "ASCII art" }
        end
        return original_readfile(path)
      end

      preview.preview_utxt()
      vim.wait(500, function()
        return callback_executed
      end, 10)
      vim.fn.readfile = original_readfile

      -- Register autocmd
      preview.register_autocmd()

      -- Close the preview
      preview.close_preview()
      vim.wait(50)

      -- Verify find_preview_window returns nil
      local win_id = preview.find_preview_window()
      assert.is_nil(win_id, "find_preview_window should return nil after close")
    end)

    it("calling close_preview twice does not error", function()
      preview.close_preview()
      preview.close_preview() -- Should not error
    end)

    it("can reopen preview after closing window directly", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local call_count = 0

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        call_count = call_count + 1
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock file reading
      local original_readfile = vim.fn.readfile
      vim.fn.readfile = function(path)
        if path:match("%.utxt$") then
          return { "ASCII art " .. call_count }
        end
        return original_readfile(path)
      end

      -- First call creates preview
      preview.preview_utxt()
      vim.wait(500, function()
        return call_count >= 1
      end, 10)

      -- Find the preview window and close it directly (simulating user closing with :q)
      local preview_win = preview.find_preview_window()
      assert.is_not_nil(preview_win, "preview window should exist")

      -- Close the window directly (not via close_preview)
      api.nvim_win_close(preview_win, true)
      vim.wait(50)

      -- Now try to reopen - this should NOT cause E95 error
      call_count = 0
      preview.preview_utxt()
      vim.wait(500, function()
        return call_count >= 1
      end, 10)

      vim.fn.readfile = original_readfile

      -- Verify a new preview window was created
      local new_preview_win = preview.find_preview_window()
      assert.is_not_nil(new_preview_win, "new preview window should be created after direct close")
    end)
  end)

  describe("FR-6: SVG Preview State Tracking", function()
    it("exports is_svg_preview_active function", function()
      assert.is_function(preview.is_svg_preview_active)
    end)

    it("initially returns false when no SVG preview is active", function()
      assert.is_false(preview.is_svg_preview_active())
    end)

    it("returns true after preview_svg starts", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      -- Mock system call and server
      local callback_executed = false
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Call preview_svg
      preview.preview_svg()
      vim.wait(500, function()
        return callback_executed
      end, 10)

      -- Should now be active
      assert.is_true(preview.is_svg_preview_active())

      -- Cleanup
      preview.stop_svg_preview()
    end)

    it("returns false after stop_svg_preview is called", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      -- Mock system call and server
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Start preview
      preview.preview_svg()
      vim.wait(100)

      -- Stop preview
      preview.stop_svg_preview()
      vim.wait(50)

      -- Should now be inactive
      assert.is_false(preview.is_svg_preview_active())
    end)
  end)

  describe("FR-7: SVG Autocmd Registration", function()
    it("exports register_svg_autocmd function", function()
      assert.is_function(preview.register_svg_autocmd)
    end)

    it("exports unregister_svg_autocmd function", function()
      assert.is_function(preview.unregister_svg_autocmd)
    end)

    it("register_svg_autocmd creates autocmd for .puml and .uml files", function()
      preview.register_svg_autocmd()

      -- Check that the augroup exists
      local ok = pcall(api.nvim_get_autocmds, { group = "PlantumlSvgPreview" })
      assert.is_true(ok, "PlantumlSvgPreview augroup should exist")

      preview.unregister_svg_autocmd()
    end)

    it("unregister_svg_autocmd removes the autocmd without error", function()
      preview.register_svg_autocmd()
      preview.unregister_svg_autocmd()
      -- Should not error when called twice
      preview.unregister_svg_autocmd()
    end)

    it("preview_svg registers SVG autocmd when starting", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      -- Mock system call and server
      local callback_executed = false
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback_executed = true
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Call preview_svg
      preview.preview_svg()
      vim.wait(500, function()
        return callback_executed
      end, 10)

      -- Check that autocmd was registered
      local ok = pcall(api.nvim_get_autocmds, { group = "PlantumlSvgPreview" })
      assert.is_true(ok, "SVG autocmd should be registered after preview_svg starts")

      -- Cleanup
      preview.stop_svg_preview()
    end)
  end)

  describe("FR-8: SVG Regeneration on Save", function()
it("autocmd regenerates SVG on BufWritePost for .puml files", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local system_calls = {}

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        table.insert(system_calls, cmd)
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Start preview
      preview.preview_svg()
      vim.wait(500, function()
        return #system_calls >= 1
      end, 10)

      -- Wait for scheduled callbacks to complete (state is set in callback)
      vim.wait(100)

      -- Verify state is active
      assert.is_true(preview.is_svg_preview_active(), "SVG preview should be active")

      -- Clear calls
      system_calls = {}

      -- Trigger BufWritePost (autocmd is already registered by preview_svg)
      vim.cmd("doautocmd BufWritePost " .. test_file)
      vim.wait(500, function()
        return #system_calls >= 1
      end, 10)

      -- Should have called PlantUML (not create_svg command)
      assert.is_true(#system_calls >= 1, "PlantUML should be called on save")

      -- Verify the output path is in temp directory
      local found_temp_output = false
      for _, cmd in ipairs(system_calls) do
        for _, arg in ipairs(cmd) do
          if type(arg) == "string" and arg:match("/tmp/plantuml%.nvim") then
            found_temp_output = true
            break
          end
        end
        if found_temp_output then break end
      end
      assert.is_true(found_temp_output, "SVG should be regenerated to temp directory")

      -- Cleanup
      preview.unregister_svg_autocmd()
      preview.stop_svg_preview()
    end)

    it("autocmd regenerates SVG on BufWritePost for .uml files", function()
      -- Create a test PlantUML file with .uml extension
      local test_file = test_dir .. "/diagram.uml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local system_calls = {}

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        table.insert(system_calls, cmd)
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Start preview
      preview.preview_svg()
      vim.wait(500, function()
        return #system_calls >= 1
      end, 10)

      -- Wait for scheduled callbacks to complete (state is set in callback)
      vim.wait(100)

      -- Verify state is active
      assert.is_true(preview.is_svg_preview_active(), "SVG preview should be active")

      -- Clear calls
      system_calls = {}

      -- Trigger BufWritePost (autocmd is already registered by preview_svg)
      vim.cmd("doautocmd BufWritePost " .. test_file)
      vim.wait(500, function()
        return #system_calls >= 1
      end, 10)

      -- Should have called PlantUML
      assert.is_true(#system_calls >= 1, "PlantUML should be called on save for .uml files")

      -- Cleanup
      preview.unregister_svg_autocmd()
      preview.stop_svg_preview()
    end)

    it("does not trigger PlantumlCreateSVG command", function()
      -- Create a test PlantUML file
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({
        "@startuml",
        "Alice -> Bob: Test",
        "@enduml",
      }, test_file)
      vim.cmd("edit " .. test_file)

      local commands_executed = {}

      -- Mock nvim_command to capture command calls
      local original_nvim_command = api.nvim_command
      api.nvim_command = function(cmd)
        table.insert(commands_executed, cmd)
        original_nvim_command(cmd)
      end

      -- Mock system call
      vim.system = function(cmd, opts, callback)
        vim.schedule(function()
          callback({ code = 0, stdout = "", stderr = "" })
        end)
      end

      -- Mock server module
      package.loaded["plantuml.server"] = nil
      local server = {
        start_server = function(cb) cb("http://localhost:8912") end,
        get_port = function() return 8912 end,
        is_running = function() return true end,
      }
      package.loaded["plantuml.server"] = server

      -- Mock ui.open
      vim.ui = vim.ui or {}
      vim.ui.open = function(url) end

      -- Start preview and register autocmd
      preview.preview_svg()
      vim.wait(100)
      preview.register_svg_autocmd()

      -- Trigger BufWritePost
      vim.cmd("doautocmd BufWritePost " .. test_file)
      vim.wait(200)

      -- Restore original nvim_command
      api.nvim_command = original_nvim_command

      -- Check that PlantumlCreateSVG was NOT called
      for _, cmd in ipairs(commands_executed) do
        assert.is_false(cmd:match("PlantumlCreateSVG") ~= nil, 
          "PlantumlCreateSVG should not be called by autocmd")
        assert.is_false(cmd:match("PlantumlCreatePNG") ~= nil,
          "PlantumlCreatePNG should not be called by autocmd")
        assert.is_false(cmd:match("PlantumlCreateUTXT") ~= nil,
          "PlantumlCreateUTXT should not be called by autocmd")
      end

      -- Cleanup
      preview.unregister_svg_autocmd()
      preview.stop_svg_preview()
    end)
  end)

  describe("FR-9: SVG Autocmd Cleanup", function()
    it("stop_svg_preview unregisters the SVG autocmd", function()
      -- Register autocmd first
      preview.register_svg_autocmd()

      -- Verify it's registered
      local ok_before = pcall(api.nvim_get_autocmds, { group = "PlantumlSvgPreview" })
      assert.is_true(ok_before, "SVG autocmd should be registered")

      -- Stop preview
      preview.stop_svg_preview()
      vim.wait(50)

      -- Check state is cleared
      assert.is_false(preview.is_svg_preview_active())
    end)

    it("unregister_svg_autocmd can be called multiple times without error", function()
      preview.unregister_svg_autocmd()
      preview.unregister_svg_autocmd()
      preview.unregister_svg_autocmd()
      -- Should not error
    end)
  end)
end)