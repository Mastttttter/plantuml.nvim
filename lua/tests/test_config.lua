-- Test configuration module
local config = require("plantuml.config")

describe("config module", function()
  -- Store original functions for cleanup
  local original_executable
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
    
    -- Reset module state by requiring it fresh
    package.loaded["plantuml.config"] = nil
    config = require("plantuml.config")
  end)

  after_each(function()
    -- Restore original functions
    vim.notify = original_notify
    if original_executable then
      vim.fn.executable = original_executable
    end
  end)

  describe("FR-1: Configuration Schema Definition", function()
    it("setup() with no opts returns all default values", function()
      -- Mock executable to return 1 for everything
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1 -- All executables available
      end
      
      local cfg = config.setup()
      
      assert.are.equal("java", cfg.java_cmd)
      assert.are.equal(nil, cfg.plantuml_jar)
      assert.are.equal("inkscape", cfg.inkscape_cmd)
      assert.are.equal(8080, cfg.server_port)
      assert.are.equal("plantuml", cfg.plantuml_cmd)
    end)

    it("setup() with empty table {} returns defaults", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1
      end
      
      local cfg = config.setup({})
      
      assert.are.equal("java", cfg.java_cmd)
      assert.are.equal(8080, cfg.server_port)
    end)

    it("get() before setup() returns defaults", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1
      end
      
      local cfg = config.get()
      
      assert.are.equal("java", cfg.java_cmd)
      assert.are.equal(8080, cfg.server_port)
    end)
  end)

  describe("FR-2: Setup Function with Merging", function()
    it("setup() with partial opts merges correctly", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1
      end
      
      local cfg = config.setup({
        java_cmd = "/usr/bin/java",
        server_port = 9000,
      })
      
      assert.are.equal("/usr/bin/java", cfg.java_cmd)
      assert.are.equal(9000, cfg.server_port)
      assert.are.equal("inkscape", cfg.inkscape_cmd) -- default retained
    end)

    it("setup() with nil values uses defaults", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1
      end
      
      local cfg = config.setup({
        java_cmd = nil,
        server_port = 9000,
      })
      
      assert.are.equal("java", cfg.java_cmd) -- default used
      assert.are.equal(9000, cfg.server_port)
    end)

    it("setup() with all opts specified overrides all defaults", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "plantuml" then
          return 0 -- plantuml not available, use java
        end
        return 1
      end
      
      local cfg = config.setup({
        java_cmd = "/custom/java",
        plantuml_jar = "/custom/plantuml.jar",
        inkscape_cmd = "/custom/inkscape",
        server_port = 9999,
      })
      
      assert.are.equal("/custom/java", cfg.java_cmd)
      assert.are.equal("/custom/plantuml.jar", cfg.plantuml_jar)
      assert.are.equal("/custom/inkscape", cfg.inkscape_cmd)
      assert.are.equal(9999, cfg.server_port)
      assert.are.equal("/custom/java -jar /custom/plantuml.jar", cfg.plantuml_cmd)
    end)
  end)

  describe("FR-3: PlantUML Executable Detection", function()
    it("detects system plantuml when available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "plantuml" then
          return 1
        end
        return 0
      end
      
      local cfg = config.setup()
      
      assert.are.equal("plantuml", cfg.plantuml_cmd)
    end)

    it("uses java -jar pattern when plantuml_jar is set and plantuml not available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "plantuml" then
          return 0 -- not available
        elseif cmd == "java" then
          return 1 -- java available
        end
        return 0
      end
      
      local cfg = config.setup({
        plantuml_jar = "/path/to/plantuml.jar",
      })
      
      assert.are.equal("java -jar /path/to/plantuml.jar", cfg.plantuml_cmd)
    end)

    it("returns nil for plantuml_cmd when neither plantuml nor plantuml_jar available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 0 -- nothing available
      end
      
      local cfg = config.setup()
      
      assert.are.equal(nil, cfg.plantuml_cmd)
    end)

    it("prefers system plantuml over java -jar when both available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "plantuml" or cmd == "java" then
          return 1
        end
        return 0
      end
      
      local cfg = config.setup({
        plantuml_jar = "/path/to/plantuml.jar",
      })
      
      assert.are.equal("plantuml", cfg.plantuml_cmd)
    end)
  end)

  describe("FR-4: Tool Validation with Error Messages", function()
    it("shows no error when plantuml available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 1 -- all available
      end
      
      config.setup()
      
      -- Check no error messages
      for _, msg in ipairs(notify_messages) do
        assert.is_not_true(msg.level == vim.log.levels.ERROR)
      end
    end)

    it("shows error when neither plantuml nor java available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        return 0 -- nothing available
      end
      
      config.setup()
      
      -- Check for error message about missing tools
      local found_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR and 
           (msg.msg:match("plantuml") or msg.msg:match("java")) then
          found_error = true
          break
        end
      end
      assert.is_true(found_error)
    end)

    it("shows error when plantuml_jar set but java not available", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "java" then
          return 0 -- java not available
        end
        return 0
      end
      
      config.setup({
        plantuml_jar = "/path/to/plantuml.jar",
      })
      
      -- Check for error about missing java
      local found_java_error = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.ERROR and msg.msg:match("java") then
          found_java_error = true
          break
        end
      end
      assert.is_true(found_java_error)
    end)

    it("shows warning when inkscape not available (not error)", function()
      original_executable = vim.fn.executable
      vim.fn.executable = function(cmd)
        if cmd == "inkscape" then
          return 0 -- not available
        end
        return 1 -- others available
      end
      
      config.setup()
      
      -- Check for warning (not error) about missing inkscape
      local found_warning = false
      for _, msg in ipairs(notify_messages) do
        if msg.level == vim.log.levels.WARN and msg.msg:match("inkscape") then
          found_warning = true
          break
        end
      end
      assert.is_true(found_warning)
    end)
  end)
end)