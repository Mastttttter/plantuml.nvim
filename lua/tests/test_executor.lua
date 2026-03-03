-- Test executor module
local executor = require("plantuml.executor")
local config = require("plantuml.config")
local uv = vim.loop

describe("executor module", function()
  -- Store original functions for cleanup
  local original_system
  local original_notify
  local notify_messages
  local test_dir
  local original_executable

  before_each(function()
    -- Create test directory
    test_dir = uv.fs_mkdtemp("/tmp/plantuml_executor_test_XXXXXX")

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
    config = require("plantuml.config")
    executor = require("plantuml.executor")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.system = original_system
    vim.fn.executable = original_executable

    -- Cleanup test directories
    if test_dir and uv.fs_stat(test_dir) then
      local function rm_dir(path)
        local handle = uv.fs_scandir(path)
        if handle then
          while true do
            local name, type = uv.fs_scandir_next(handle)
            if not name then
              break
            end
            local full_path = path .. "/" .. name
            if type == "directory" then
              rm_dir(full_path)
            else
              uv.fs_unlink(full_path)
            end
          end
        end
        uv.fs_rmdir(path)
      end
      rm_dir(test_dir)
    end
  end)

  describe("FR-1: run_plantuml", function()
    it("executes plantuml command with correct arguments for svg format", function()
      local captured_cmd = nil
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        captured_opts = opts
        -- Simulate success
        callback({ code = 0, stdout = "success output", stderr = "" })
      end

      config.setup({ plantuml_jar = nil })
      executor = require("plantuml.executor")

      local input_file = test_dir .. "/diagram.puml"
      local output_path = test_dir .. "/output/diagram.svg"
      local callback_called = false
      local callback_success = nil
      local callback_output = nil

      executor.run_plantuml(input_file, output_path, "svg", function(success, output)
        callback_called = true
        callback_success = success
        callback_output = output
      end)

      assert.is_true(callback_called)
      assert.is_true(callback_success)
      assert.are.equal("success output", callback_output)

      -- Verify command construction
      assert.is_not_nil(captured_cmd)
      assert.is_true(#captured_cmd >= 3)
      -- Should contain -tsvg, input file, and output path
      local has_format = false
      local has_input = false
      local has_output = false
      for _, arg in ipairs(captured_cmd) do
        if arg == "-tsvg" then has_format = true end
        if arg == input_file then has_input = true end
        if arg == "-o" then has_output = true end
      end
      assert.is_true(has_format, "should have -tsvg flag")
      assert.is_true(has_input, "should have input file")
    end)

    it("executes plantuml command with correct arguments for png format", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "png output", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local input_file = test_dir .. "/diagram.puml"
      local output_path = test_dir .. "/output/diagram.png"

      executor.run_plantuml(input_file, output_path, "png", function(success, output)
        assert.is_true(success)
        assert.are.equal("png output", output)
      end)

      -- Verify -tpng flag
      local has_format = false
      for _, arg in ipairs(captured_cmd) do
        if arg == "-tpng" then has_format = true end
      end
      assert.is_true(has_format, "should have -tpng flag")
    end)

    it("executes plantuml command with correct arguments for utxt format", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "utxt output", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local input_file = test_dir .. "/diagram.puml"
      local output_path = test_dir .. "/output/diagram.utxt"

      executor.run_plantuml(input_file, output_path, "utxt", function(success, output)
        assert.is_true(success)
        assert.are.equal("utxt output", output)
      end)

      -- Verify -tutxt flag
      local has_format = false
      for _, arg in ipairs(captured_cmd) do
        if arg == "-tutxt" then has_format = true end
      end
      assert.is_true(has_format, "should have -tutxt flag")
    end)

    it("handles non-zero exit code with error notification", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "Error: syntax error" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local input_file = test_dir .. "/diagram.puml"
      local output_path = test_dir .. "/output/diagram.svg"

      executor.run_plantuml(input_file, output_path, "svg", function(success, output)
        assert.is_false(success)
        assert.are.equal("Error: syntax error", output)
      end)

      -- Check that vim.notify was called with ERROR level
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
          assert.is_true(msg.msg:match("PlantUML") ~= nil or msg.msg:match("error") ~= nil)
          break
        end
      end
      assert.is_true(found_error, "should have called vim.notify with ERROR level")
    end)

    it("calls callback with (success, output_or_error) tuple on success", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "generated output", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local callback_args = nil
      executor.run_plantuml(test_dir .. "/input.puml", test_dir .. "/output.svg", "svg", function(success, output)
        callback_args = { success = success, output = output }
      end)

      assert.is_not_nil(callback_args)
      assert.is_true(callback_args.success)
      assert.are.equal("generated output", callback_args.output)
    end)

    it("calls callback with (false, stderr) on failure", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "compilation failed" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local callback_args = nil
      executor.run_plantuml(test_dir .. "/input.puml", test_dir .. "/output.svg", "svg", function(success, output)
        callback_args = { success = success, output = output }
      end)

      assert.is_not_nil(callback_args)
      assert.is_false(callback_args.success)
      assert.are.equal("compilation failed", callback_args.output)
    end)

    it("uses java -jar pattern when plantuml_jar is configured", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "", stderr = "" })
      end

      vim.fn.executable = function(cmd)
        if cmd == "java" then return 1 end
        if cmd == "plantuml" then return 0 end -- system plantuml not available
        return 0
      end

      config.setup({ plantuml_jar = "/path/to/plantuml.jar" })
      executor = require("plantuml.executor")

      executor.run_plantuml(test_dir .. "/input.puml", test_dir .. "/output.svg", "svg", function() end)

      -- Should use java -jar pattern
      assert.is_not_nil(captured_cmd)
      assert.are.equal("java", captured_cmd[1])
      assert.are.equal("-jar", captured_cmd[2])
      assert.are.equal("/path/to/plantuml.jar", captured_cmd[3])
    end)
  end)

  describe("FR-2: run_inkscape", function()
    it("executes inkscape command with correct arguments", function()
      local captured_cmd = nil
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        captured_opts = opts
        callback({ code = 0, stdout = "converted", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local svg_path = test_dir .. "/diagram.svg"
      local png_path = test_dir .. "/diagram.png"
      local dpi = 800

      executor.run_inkscape(svg_path, png_path, dpi, function(success, output)
        assert.is_true(success)
        assert.are.equal("converted", output)
      end)

      -- Verify command construction
      assert.is_not_nil(captured_cmd)
      assert.are.equal("inkscape", captured_cmd[1])

      -- Check for export arguments
      local has_export_filename = false
      local has_export_dpi = false
      local has_svg_path = false
      local has_png_path = false

      for i, arg in ipairs(captured_cmd) do
        if arg == "--export-filename" then
          has_export_filename = true
          assert.are.equal(png_path, captured_cmd[i + 1])
          has_png_path = true
        end
        if arg == "--export-dpi" then
          has_export_dpi = true
          assert.are.equal(tostring(dpi), captured_cmd[i + 1])
        end
        if arg == svg_path then
          has_svg_path = true
        end
      end

      assert.is_true(has_export_filename, "should have --export-filename")
      assert.is_true(has_export_dpi, "should have --export-dpi")
      assert.is_true(has_svg_path, "should have svg input path")
      assert.is_true(has_png_path, "should have png output path")
    end)

    it("handles non-zero exit code with error notification", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "Inkscape error" })
      end

      config.setup()
      executor = require("plantuml.executor")

      executor.run_inkscape(test_dir .. "/input.svg", test_dir .. "/output.png", 800, function(success, output)
        assert.is_false(success)
        assert.are.equal("Inkscape error", output)
      end)

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

    it("calls callback with (success, output_or_error) tuple on success", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "conversion done", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local callback_args = nil
      executor.run_inkscape(test_dir .. "/input.svg", test_dir .. "/output.png", 150, function(success, output)
        callback_args = { success = success, output = output }
      end)

      assert.is_not_nil(callback_args)
      assert.is_true(callback_args.success)
      assert.are.equal("conversion done", callback_args.output)
    end)

    it("calls callback with (false, stderr) on failure", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "failed to convert" })
      end

      config.setup()
      executor = require("plantuml.executor")

      local callback_args = nil
      executor.run_inkscape(test_dir .. "/input.svg", test_dir .. "/output.png", 800, function(success, output)
        callback_args = { success = success, output = output }
      end)

      assert.is_not_nil(callback_args)
      assert.is_false(callback_args.success)
      assert.are.equal("failed to convert", callback_args.output)
    end)

    it("uses custom inkscape_cmd from config", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        callback({ code = 0, stdout = "", stderr = "" })
      end

      vim.fn.executable = function(cmd)
        return 1
      end

      config.setup({ inkscape_cmd = "/custom/path/inkscape" })
      executor = require("plantuml.executor")

      executor.run_inkscape(test_dir .. "/input.svg", test_dir .. "/output.png", 800, function() end)

      assert.is_not_nil(captured_cmd)
      assert.are.equal("/custom/path/inkscape", captured_cmd[1])
    end)
  end)

  describe("FR-3: Error handling", function()
    it("vim.system is called with text = true option", function()
      local captured_opts = nil

      vim.system = function(cmd, opts, callback)
        captured_opts = opts
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      executor = require("plantuml.executor")

      executor.run_plantuml(test_dir .. "/input.puml", test_dir .. "/output.svg", "svg", function() end)

      assert.is_not_nil(captured_opts)
      assert.is_true(captured_opts.text, "vim.system should be called with text = true")
    end)

    it("error message includes exit code", function()
      vim.system = function(cmd, opts, callback)
        callback({ code = 42, stdout = "", stderr = "some error" })
      end

      config.setup()
      executor = require("plantuml.executor")

      executor.run_plantuml(test_dir .. "/input.puml", test_dir .. "/output.svg", "svg", function() end)

      -- Check error message includes exit code
      local found_exit_code = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR and msg.msg:match("42") then
          found_exit_code = true
          break
        end
      end
      assert.is_true(found_exit_code, "error message should include exit code")
    end)
  end)

  describe("FR-4: Module exports", function()
    it("exports run_plantuml function", function()
      assert.is_not_nil(executor.run_plantuml)
      assert.is_true(type(executor.run_plantuml) == "function")
    end)

    it("exports run_inkscape function", function()
      assert.is_not_nil(executor.run_inkscape)
      assert.is_true(type(executor.run_inkscape) == "function")
    end)
  end)
end)
