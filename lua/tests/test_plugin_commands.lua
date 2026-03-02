-- Test plugin/plantuml.lua command registration
local api = vim.api

describe("plugin commands", function()
  -- Store original functions for cleanup
  local original_notify
  local original_executable
  local notify_messages
  local original_commands
  local test_dir

  before_each(function()
    -- Create test directory
    test_dir = vim.fn.fnamemodify(vim.fn.tempname(), ":h") .. "/plantuml_plugin_test_" .. os.time()
    vim.fn.mkdir(test_dir, "p")

    -- Reset notify messages tracker
    notify_messages = {}

    -- Mock vim.notify to capture messages
    original_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(notify_messages, { msg = msg, level = level })
    end

    -- Mock executable for config
    original_executable = vim.fn.executable
    vim.fn.executable = function(cmd)
      return 1 -- All executables available
    end

    -- Track existing commands
    original_commands = {}
    local cmds = api.nvim_get_commands({ builtin = false })
    for name, _ in pairs(cmds) do
      original_commands[name] = true
    end

    -- Reset module state
    package.loaded["plantuml.config"] = nil
    package.loaded["plantuml.executor"] = nil
    package.loaded["plantuml.preview"] = nil
    package.loaded["plantuml.creator"] = nil
    package.loaded["plantuml.server"] = nil
    package.loaded["plantuml.util"] = nil
    package.loaded["plantuml"] = nil

    -- Initialize config
    local config = require("plantuml.config")
    config.setup()
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    vim.fn.executable = original_executable

    -- Clean up any commands created during tests
    local cmds = api.nvim_get_commands({ builtin = false })
    for name, _ in pairs(cmds) do
      if not original_commands[name] then
        pcall(api.nvim_del_user_command, name)
      end
    end

    -- Clean up augroups
    pcall(api.nvim_del_augroup_by_name, "PlantumlPlugin")

    -- Clean up test directories
    if test_dir and vim.fn.isdirectory(test_dir) == 1 then
      vim.fn.delete(test_dir, "rf")
    end
  end)

  describe("FR-1: Command registration", function()
    it("registers PlantumlPreview command", function()
      -- Source the plugin file
      vim.cmd("source plugin/plantuml.lua")

      local cmds = api.nvim_get_commands({ builtin = false })
      assert.is_not_nil(cmds["PlantumlPreview"])
    end)

    it("registers PlantumlPreviewUTXT command", function()
      vim.cmd("source plugin/plantuml.lua")

      local cmds = api.nvim_get_commands({ builtin = false })
      assert.is_not_nil(cmds["PlantumlPreviewUTXT"])
    end)

    it("registers PlantumlCreateSVG command", function()
      vim.cmd("source plugin/plantuml.lua")

      local cmds = api.nvim_get_commands({ builtin = false })
      assert.is_not_nil(cmds["PlantumlCreateSVG"])
    end)

    it("registers PlantumlCreatePNG command", function()
      vim.cmd("source plugin/plantuml.lua")

      local cmds = api.nvim_get_commands({ builtin = false })
      assert.is_not_nil(cmds["PlantumlCreatePNG"])
    end)

    it("registers PlantumlCreateUTXT command", function()
      vim.cmd("source plugin/plantuml.lua")

      local cmds = api.nvim_get_commands({ builtin = false })
      assert.is_not_nil(cmds["PlantumlCreateUTXT"])
    end)
  end)

  describe("FR-2: Command execution", function()
    it("PlantumlPreview calls plantuml.preview()", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      local original_preview = plantuml.preview
      plantuml.preview = function()
        called = true
      end

      -- Create a test .puml file and open it
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlPreview")

      assert.is_true(called)
      plantuml.preview = original_preview
    end)

    it("PlantumlPreviewUTXT calls plantuml.preview_utxt()", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      local original_preview_utxt = plantuml.preview_utxt
      plantuml.preview_utxt = function()
        called = true
      end

      -- Create a test .puml file and open it
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlPreviewUTXT")

      assert.is_true(called)
      plantuml.preview_utxt = original_preview_utxt
    end)

    it("PlantumlCreateSVG calls plantuml.create_svg()", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      local original_create_svg = plantuml.create_svg
      plantuml.create_svg = function()
        called = true
      end

      -- Create a test .puml file and open it
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlCreateSVG")

      assert.is_true(called)
      plantuml.create_svg = original_create_svg
    end)

    it("PlantumlCreatePNG calls plantuml.create_png()", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      local original_create_png = plantuml.create_png
      plantuml.create_png = function()
        called = true
      end

      -- Create a test .puml file and open it
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlCreatePNG")

      assert.is_true(called)
      plantuml.create_png = original_create_png
    end)

    it("PlantumlCreateUTXT calls plantuml.create_utxt()", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      local original_create_utxt = plantuml.create_utxt
      plantuml.create_utxt = function()
        called = true
      end

      -- Create a test .puml file and open it
      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlCreateUTXT")

      assert.is_true(called)
      plantuml.create_utxt = original_create_utxt
    end)
  end)

  describe("FR-3: VimLeave autocmd for cleanup", function()
    it("creates PlantumlPlugin augroup on load", function()
      vim.cmd("source plugin/plantuml.lua")

      -- Check that augroup exists
      local ok = pcall(api.nvim_get_autocmds, { group = "PlantumlPlugin" })
      assert.is_true(ok)
    end)

    it("registers VimLeave autocmd for cleanup", function()
      vim.cmd("source plugin/plantuml.lua")

      -- Check for VimLeave autocmd
      local autocmds = api.nvim_get_autocmds({ group = "PlantumlPlugin", event = "VimLeave" })
      assert.is_true(#autocmds > 0, "VimLeave autocmd should be registered")
    end)

    it("VimLeave autocmd calls server.stop_server()", function()
      vim.cmd("source plugin/plantuml.lua")

      local server = require("plantuml.server")
      local called = false
      local original_stop = server.stop_server
      server.stop_server = function()
        called = true
      end

      -- Trigger VimLeave
      vim.cmd("doautocmd VimLeave")

      -- Wait a bit for async
      vim.wait(50)

      assert.is_true(called, "stop_server should be called on VimLeave")
      server.stop_server = original_stop
    end)
  end)

  describe("FR-4: Commands work on .puml and .uml files", function()
    it("commands work on .puml files", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      plantuml.preview = function()
        called = true
      end

      local test_file = test_dir .. "/diagram.puml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlPreview")

      assert.is_true(called)
    end)

    it("commands work on .uml files", function()
      vim.cmd("source plugin/plantuml.lua")

      local plantuml = require("plantuml")
      local called = false
      plantuml.preview = function()
        called = true
      end

      local test_file = test_dir .. "/diagram.uml"
      vim.fn.writefile({ "@startuml", "Alice -> Bob", "@enduml" }, test_file)
      vim.cmd("edit " .. test_file)

      vim.cmd("PlantumlPreview")

      assert.is_true(called)
    end)
  end)
end)