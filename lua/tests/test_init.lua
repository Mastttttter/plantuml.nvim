-- Test init module (public API)
local api = vim.api

describe("init module (public API)", function()
  -- Store original functions for cleanup
  local original_notify
  local original_executable
  local notify_messages
  local original_commands

  before_each(function()
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
  end)

  describe("FR-1: Public API exports", function()
    it("exports setup() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.setup)
    end)

    it("exports preview() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.preview)
    end)

    it("exports preview_utxt() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.preview_utxt)
    end)

    it("exports create_svg() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.create_svg)
    end)

    it("exports create_png() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.create_png)
    end)

    it("exports create_utxt() function", function()
      local plantuml = require("plantuml")
      assert.is_function(plantuml.create_utxt)
    end)

    it("setup() calls config.setup() with user options", function()
      local config = require("plantuml.config")
      local plantuml = require("plantuml")

      plantuml.setup({ server_port = 9999 })

      local cfg = config.get()
      assert.are.equal(9999, cfg.server_port)
    end)

    it("setup() returns the module for chaining", function()
      local plantuml = require("plantuml")
      local result = plantuml.setup()
      assert.are.equal(plantuml, result)
    end)
  end)

  describe("FR-2: preview() delegates to preview_svg", function()
    it("preview() calls preview.preview_svg", function()
      local plantuml = require("plantuml")
      local preview = require("plantuml.preview")

      -- Track if preview_svg was called
      local called = false
      local original_preview_svg = preview.preview_svg
      preview.preview_svg = function()
        called = true
      end

      plantuml.preview()

      assert.is_true(called)
      preview.preview_svg = original_preview_svg
    end)
  end)

  describe("FR-3: preview_utxt() delegates to preview module", function()
    it("preview_utxt() calls preview.preview_utxt", function()
      local plantuml = require("plantuml")
      local preview = require("plantuml.preview")

      -- Track if preview_utxt was called
      local called = false
      local original_preview_utxt = preview.preview_utxt
      preview.preview_utxt = function()
        called = true
      end

      plantuml.preview_utxt()

      assert.is_true(called)
      preview.preview_utxt = original_preview_utxt
    end)
  end)

  describe("FR-4: create_svg() delegates to creator module", function()
    it("create_svg() calls creator.create_svg", function()
      local plantuml = require("plantuml")
      local creator = require("plantuml.creator")

      -- Track if create_svg was called
      local called = false
      local original_create_svg = creator.create_svg
      creator.create_svg = function()
        called = true
      end

      plantuml.create_svg()

      assert.is_true(called)
      creator.create_svg = original_create_svg
    end)
  end)

  describe("FR-5: create_png() delegates to creator module", function()
    it("create_png() calls creator.create_png", function()
      local plantuml = require("plantuml")
      local creator = require("plantuml.creator")

      -- Track if create_png was called
      local called = false
      local original_create_png = creator.create_png
      creator.create_png = function()
        called = true
      end

      plantuml.create_png()

      assert.is_true(called)
      creator.create_png = original_create_png
    end)
  end)

  describe("FR-6: create_utxt() delegates to creator module", function()
    it("create_utxt() calls creator.create_utxt", function()
      local plantuml = require("plantuml")
      local creator = require("plantuml.creator")

      -- Track if create_utxt was called
      local called = false
      local original_create_utxt = creator.create_utxt
      creator.create_utxt = function()
        called = true
      end

      plantuml.create_utxt()

      assert.is_true(called)
      creator.create_utxt = original_create_utxt
    end)
  end)
end)