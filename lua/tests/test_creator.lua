-- Test creator module
local creator = require("plantuml.creator")
local executor = require("plantuml.executor")
local util = require("plantuml.util")
local config = require("plantuml.config")
local uv = vim.loop

describe("creator module", function()
  -- Store original functions for cleanup
  local original_system
  local original_notify
  local notify_messages
  local test_dir
  local original_executable
  local original_buf_get_name
  local original_get_current_buf

  before_each(function()
    -- Create test directory
    test_dir = uv.fs_mkdtemp("/tmp/plantuml_creator_test_XXXXXX")

    -- Create .git directory so get_project_folder returns test_dir
    uv.fs_mkdir(test_dir .. "/.git", 493)

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

    -- Mock buffer functions
    original_buf_get_name = vim.api.nvim_buf_get_name
    original_get_current_buf = vim.api.nvim_get_current_buf

    -- Reset module state
    package.loaded["plantuml.config"] = nil
    package.loaded["plantuml.executor"] = nil
    package.loaded["plantuml.util"] = nil
    package.loaded["plantuml.creator"] = nil
    config = require("plantuml.config")
    executor = require("plantuml.executor")
    util = require("plantuml.util")
    creator = require("plantuml.creator")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.system = original_system
    vim.fn.executable = original_executable
    vim.api.nvim_buf_get_name = original_buf_get_name
    vim.api.nvim_get_current_buf = original_get_current_buf

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

  describe("FR-1: create_svg", function()
    it("exports create_svg function", function()
      assert.is_not_nil(creator.create_svg)
      assert.is_true(type(creator.create_svg) == "function")
    end)

    it("generates SVG and saves to umlout/svg/ directory", function()
      local captured_cmd = nil
      local test_file = test_dir .. "/diagram.puml"
      local output_dir = test_dir .. "/umlout/svg"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nAlice -> Bob\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      -- Mock vim.system
      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        -- Create the output directory and file to simulate success
        uv.fs_mkdir(test_dir .. "/umlout", 493)
        uv.fs_mkdir(output_dir, 493)
        local out = io.open(output_dir .. "/diagram.svg", "w")
        if out then
          out:write("<svg>test</svg>")
          out:close()
        end
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      local callback_called = false
      creator.create_svg(function(success)
        callback_called = true
        assert.is_true(success)
      end)

      assert.is_true(callback_called)

      -- Verify -tsvg flag
      local has_format = false
      for _, arg in ipairs(captured_cmd) do
        if arg == "-tsvg" then
          has_format = true
        end
      end
      assert.is_true(has_format, "should have -tsvg flag")
    end)

    it("creates output directory if it doesn't exist", function()
      local test_file = test_dir .. "/diagram.puml"
      local output_dir = test_dir .. "/umlout/svg"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      -- Mock vim.system to check if directory is created
      local dir_created = false
      vim.system = function(cmd, opts, callback)
        -- Check if output directory exists (should be created by creator)
        if uv.fs_stat(output_dir) then
          dir_created = true
        end
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_svg(function() end)

      -- Directory should be created
      assert.is_true(uv.fs_stat(output_dir) ~= nil, "output directory should be created")
    end)

    it("notifies user with output path on success", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_svg(function() end)

      -- Check notification
      local found_success = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.INFO and msg.msg:match("svg") then
          found_success = true
        end
      end
      assert.is_true(found_success, "should have success notification with svg path")
    end)

    it("notifies user with error message on failure", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "syntax error" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_svg(function() end)

      -- Check error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error, "should have error notification")
    end)
  end)

  describe("FR-2: create_png", function()
    it("exports create_png function", function()
      assert.is_not_nil(creator.create_png)
      assert.is_true(type(creator.create_png) == "function")
    end)

    it("chains SVG generation then Inkscape conversion", function()
      local test_file = test_dir .. "/diagram.puml"
      local svg_path = test_dir .. "/umlout/svg/diagram.svg"
      local png_path = test_dir .. "/umlout/png/diagram.png"
      local call_order = {}

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          table.insert(call_order, "plantuml")
          -- Create SVG file
          uv.fs_mkdir(test_dir .. "/umlout", 493)
          uv.fs_mkdir(test_dir .. "/umlout/svg", 493)
          local out = io.open(svg_path, "w")
          if out then
            out:write("<svg>test</svg>")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        elseif cmd[1] == "inkscape" then
          table.insert(call_order, "inkscape")
          -- Create PNG file
          uv.fs_mkdir(test_dir .. "/umlout/png", 493)
          local out = io.open(png_path, "w")
          if out then
            out:write("PNGDATA")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        end
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      local callback_called = false
      creator.create_png(function(success)
        callback_called = true
        assert.is_true(success)
      end)

      assert.is_true(callback_called)
      -- Verify call order: plantuml first, then inkscape
      assert.are.equal("plantuml", call_order[1])
      assert.are.equal("inkscape", call_order[2])
    end)

    it("saves PNG to umlout/png/ directory", function()
      local test_file = test_dir .. "/diagram.puml"
      local png_path = test_dir .. "/umlout/png/diagram.png"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          uv.fs_mkdir(test_dir .. "/umlout/svg", 493)
          local out = io.open(test_dir .. "/umlout/svg/diagram.svg", "w")
          if out then
            out:write("<svg>test</svg>")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        elseif cmd[1] == "inkscape" then
          uv.fs_mkdir(test_dir .. "/umlout/png", 493)
          local out = io.open(png_path, "w")
          if out then
            out:write("PNGDATA")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        end
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_png(function(success)
        assert.is_true(success)
      end)

      -- Verify PNG file exists
      assert.is_true(uv.fs_stat(png_path) ~= nil, "PNG file should be created")
    end)

    it("notifies error if SVG generation fails", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      local inkscape_called = false
      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          callback({ code = 1, stdout = "", stderr = "plantuml error" })
        elseif cmd[1] == "inkscape" then
          inkscape_called = true
          callback({ code = 0, stdout = "", stderr = "" })
        end
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_png(function(success)
        assert.is_false(success)
      end)

      -- Inkscape should not be called if SVG fails
      assert.is_false(inkscape_called, "inkscape should not be called if SVG fails")
    end)

    it("notifies error if Inkscape fails", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          uv.fs_mkdir(test_dir .. "/umlout/svg", 493)
          local out = io.open(test_dir .. "/umlout/svg/diagram.svg", "w")
          if out then
            out:write("<svg>test</svg>")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        elseif cmd[1] == "inkscape" then
          callback({ code = 1, stdout = "", stderr = "inkscape error" })
        end
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_png(function(success)
        assert.is_false(success)
      end)

      -- Check error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error, "should have error notification")
    end)

    it("uses default DPI of 800 for Inkscape export", function()
      local test_file = test_dir .. "/diagram.puml"
      local captured_dpi = nil

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          uv.fs_mkdir(test_dir .. "/umlout/svg", 493)
          local out = io.open(test_dir .. "/umlout/svg/diagram.svg", "w")
          if out then
            out:write("<svg>test</svg>")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        elseif cmd[1] == "inkscape" then
          -- Capture DPI argument
          for i, arg in ipairs(cmd) do
            if arg == "--export-dpi" then
              captured_dpi = cmd[i + 1]
            end
          end
          uv.fs_mkdir(test_dir .. "/umlout/png", 493)
          local out = io.open(test_dir .. "/umlout/png/diagram.png", "w")
          if out then
            out:write("PNGDATA")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        end
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_png(function() end)

      assert.are.equal("800", captured_dpi)
    end)

    it("uses configured png_dpi from config for Inkscape export", function()
      local test_file = test_dir .. "/diagram.puml"
      local captured_dpi = nil

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        if cmd[1] == "plantuml" or cmd[1] == "java" then
          uv.fs_mkdir(test_dir .. "/umlout/svg", 493)
          local out = io.open(test_dir .. "/umlout/svg/diagram.svg", "w")
          if out then
            out:write("<svg>test</svg>")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        elseif cmd[1] == "inkscape" then
          -- Capture DPI argument
          for i, arg in ipairs(cmd) do
            if arg == "--export-dpi" then
              captured_dpi = cmd[i + 1]
            end
          end
          uv.fs_mkdir(test_dir .. "/umlout/png", 493)
          local out = io.open(test_dir .. "/umlout/png/diagram.png", "w")
          if out then
            out:write("PNGDATA")
            out:close()
          end
          callback({ code = 0, stdout = "", stderr = "" })
        end
      end

      -- Configure custom DPI
      config.setup({ png_dpi = 400 })
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_png(function() end)

      assert.are.equal("400", captured_dpi)
    end)
  end)

  describe("FR-3: create_utxt", function()
    it("exports create_utxt function", function()
      assert.is_not_nil(creator.create_utxt)
      assert.is_true(type(creator.create_utxt) == "function")
    end)

    it("generates UTXT and saves to umlout/utxt/ directory", function()
      local captured_cmd = nil
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nAlice -> Bob\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd
        uv.fs_mkdir(test_dir .. "/umlout/utxt", 493)
        local out = io.open(test_dir .. "/umlout/utxt/diagram.utxt", "w")
        if out then
          out:write("UTXT output")
          out:close()
        end
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      local callback_called = false
      creator.create_utxt(function(success)
        callback_called = true
        assert.is_true(success)
      end)

      assert.is_true(callback_called)

      -- Verify -tutxt flag
      local has_format = false
      for _, arg in ipairs(captured_cmd) do
        if arg == "-tutxt" then
          has_format = true
        end
      end
      assert.is_true(has_format, "should have -tutxt flag")
    end)

    it("creates output directory if it doesn't exist", function()
      local test_file = test_dir .. "/diagram.puml"
      local output_dir = test_dir .. "/umlout/utxt"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_utxt(function() end)

      -- Directory should be created
      assert.is_true(uv.fs_stat(output_dir) ~= nil, "output directory should be created")
    end)

    it("notifies user with output path on success", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        callback({ code = 0, stdout = "", stderr = "" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_utxt(function() end)

      -- Check notification
      local found_success = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.INFO and msg.msg:match("utxt") then
          found_success = true
        end
      end
      assert.is_true(found_success, "should have success notification with utxt path")
    end)

    it("notifies user with error message on failure", function()
      local test_file = test_dir .. "/diagram.puml"

      -- Create test file
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end

      -- Mock buffer functions
      vim.api.nvim_get_current_buf = function()
        return 1
      end
      vim.api.nvim_buf_get_name = function(bufnr)
        return test_file
      end

      vim.system = function(cmd, opts, callback)
        callback({ code = 1, stdout = "", stderr = "syntax error" })
      end

      config.setup()
      package.loaded["plantuml.creator"] = nil
      creator = require("plantuml.creator")

      creator.create_utxt(function() end)

      -- Check error notification
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR then
          found_error = true
        end
      end
      assert.is_true(found_error, "should have error notification")
    end)
  end)

  describe("FR-4: Module exports", function()
    it("exports create_svg function", function()
      assert.is_not_nil(creator.create_svg)
      assert.is_true(type(creator.create_svg) == "function")
    end)

    it("exports create_png function", function()
      assert.is_not_nil(creator.create_png)
      assert.is_true(type(creator.create_png) == "function")
    end)

    it("exports create_utxt function", function()
      assert.is_not_nil(creator.create_utxt)
      assert.is_true(type(creator.create_utxt) == "function")
    end)
  end)
end)
