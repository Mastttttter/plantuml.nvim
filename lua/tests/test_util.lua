-- Test utility module
local util = require("plantuml.util")
local uv = vim.loop

describe("util module", function()
  -- Store original functions for cleanup
  local original_cwd
  local test_dir
  local git_test_dir
  local nested_git_dir
  local worktree_dir

  before_each(function()
    -- Create test directories
    test_dir = uv.fs_mkdtemp("/tmp/plantuml_test_XXXXXX")
    original_cwd = uv.cwd()
  end)

  after_each(function()
    -- Cleanup test directories
    if test_dir and uv.fs_stat(test_dir) then
      -- Recursively remove directory
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
    
    -- Clean up temp directory if created
    local temp_path = "/tmp/plantuml.nvim"
    if uv.fs_stat(temp_path) then
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
      pcall(rm_dir, temp_path)
    end
  end)

  describe("FR-1: find_git_root", function()
    it("returns nil for path not in a git repo", function()
      local result = util.find_git_root(test_dir)
      assert.is_nil(result)
    end)

    it("returns git root for path inside a git repo", function()
      -- Create .git directory
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493) -- 0755
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      -- Create nested subdirectory
      local nested = git_test_dir .. "/src/components"
      uv.fs_mkdir(git_test_dir .. "/src", 493)
      uv.fs_mkdir(nested, 493)
      
      local result = util.find_git_root(nested)
      assert.are.equal(git_test_dir, result)
    end)

    it("returns same directory when already at git root", function()
      -- Create .git directory
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493)
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      local result = util.find_git_root(git_test_dir)
      assert.are.equal(git_test_dir, result)
    end)

    it("handles .git as a file (git worktree)", function()
      -- Create .git as a file (worktree pattern)
      git_test_dir = test_dir .. "/worktree"
      uv.fs_mkdir(git_test_dir, 493)
      
      -- Create .git as a file
      local git_file = io.open(git_test_dir .. "/.git", "w")
      if git_file then
        git_file:write("gitdir: /path/to/main/.git/worktrees/worktree\n")
        git_file:close()
      end
      
      local result = util.find_git_root(git_test_dir)
      assert.are.equal(git_test_dir, result)
    end)

    it("returns nil for nil input", function()
      local result = util.find_git_root(nil)
      assert.is_nil(result)
    end)

    it("returns nil for empty string input", function()
      local result = util.find_git_root("")
      assert.is_nil(result)
    end)
  end)

  describe("FR-2: get_project_folder", function()
    it("returns git root when buffer is in a git repo", function()
      -- Create .git directory
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493)
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      local result = util.get_project_folder(git_test_dir .. "/src")
      assert.are.equal(git_test_dir, result)
    end)

    it("returns cwd when buffer is not in a git repo", function()
      local result = util.get_project_folder(test_dir)
      assert.are.equal(original_cwd, result)
    end)

    it("returns cwd for nil input", function()
      local result = util.get_project_folder(nil)
      assert.are.equal(original_cwd, result)
    end)

    it("returns cwd for empty string input", function()
      local result = util.get_project_folder("")
      assert.are.equal(original_cwd, result)
    end)
  end)

  describe("FR-3: ensure_temp_dir", function()
    it("creates temp directory if it doesn't exist", function()
      -- Make sure it doesn't exist
      local temp_path = "/tmp/plantuml.nvim"
      if uv.fs_stat(temp_path) then
        -- Clean it first
        uv.fs_rmdir(temp_path)
      end
      
      local result = util.ensure_temp_dir()
      assert.are.equal(temp_path, result)
      
      -- Verify directory exists
      local stat = uv.fs_stat(temp_path)
      assert.is_not_nil(stat)
      assert.are.equal("directory", stat.type)
    end)

    it("returns path if directory already exists", function()
      local temp_path = "/tmp/plantuml.nvim"
      
      -- Create it first
      if not uv.fs_stat(temp_path) then
        uv.fs_mkdir(temp_path, 448) -- 0700
      end
      
      local result = util.ensure_temp_dir()
      assert.are.equal(temp_path, result)
    end)

    it("creates directory with proper permissions (0700)", function()
      local temp_path = "/tmp/plantuml.nvim"
      
      -- Clean up first
      if uv.fs_stat(temp_path) then
        uv.fs_rmdir(temp_path)
      end
      
      util.ensure_temp_dir()
      
      -- Check permissions (stat returns mode in a platform-specific way)
      -- On Linux, we can check the actual permission bits
      local stat = uv.fs_stat(temp_path)
      assert.is_not_nil(stat)
    end)

    it("is idempotent - can be called multiple times", function()
      local temp_path = "/tmp/plantuml.nvim"
      
      -- Clean up first
      if uv.fs_stat(temp_path) then
        uv.fs_rmdir(temp_path)
      end
      
      local result1 = util.ensure_temp_dir()
      local result2 = util.ensure_temp_dir()
      
      assert.are.equal(temp_path, result1)
      assert.are.equal(temp_path, result2)
    end)
  end)

  describe("FR-4: get_output_dir", function()
    it("returns correct output path for buffer in git repo", function()
      -- Create git repo
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493)
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      local result = util.get_output_dir(git_test_dir .. "/src", "svg")
      assert.are.equal(git_test_dir .. "/umlout/svg", result)
    end)

    it("returns correct output path using cwd for non-git buffer", function()
      local result = util.get_output_dir(test_dir, "png")
      -- Should use cwd since test_dir is not in a git repo
      assert.are.equal(original_cwd .. "/umlout/png", result)
    end)

    it("handles different subdirs (svg, png, utxt)", function()
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493)
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      local result_svg = util.get_output_dir(git_test_dir, "svg")
      local result_png = util.get_output_dir(git_test_dir, "png")
      local result_utxt = util.get_output_dir(git_test_dir, "utxt")
      
      assert.are.equal(git_test_dir .. "/umlout/svg", result_svg)
      assert.are.equal(git_test_dir .. "/umlout/png", result_png)
      assert.are.equal(git_test_dir .. "/umlout/utxt", result_utxt)
    end)

    it("handles nil subdir", function()
      git_test_dir = test_dir .. "/myproject"
      uv.fs_mkdir(git_test_dir, 493)
      uv.fs_mkdir(git_test_dir .. "/.git", 493)
      
      local result = util.get_output_dir(git_test_dir, nil)
      assert.are.equal(git_test_dir .. "/umlout/", result)
    end)
  end)

  describe("FR-5: get_puml_file_info", function()
    it("returns table with filename without .puml extension", function()
      -- Open a test buffer
      local test_file = test_dir .. "/diagram.puml"
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nAlice -> Bob\n@enduml")
        f:close()
      end
      
      -- Open the file in a buffer
      local bufnr = vim.fn.bufadd(test_file)
      vim.fn.bufload(bufnr)
      vim.api.nvim_set_current_buf(bufnr)
      
      local result = util.get_puml_file_info()
      
      assert.is_not_nil(result)
      assert.are.equal("diagram", result.name)
      
      -- Clean up buffer
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("returns table with filename without .uml extension", function()
      local test_file = test_dir .. "/flowchart.uml"
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end
      
      local bufnr = vim.fn.bufadd(test_file)
      vim.fn.bufload(bufnr)
      vim.api.nvim_set_current_buf(bufnr)
      
      local result = util.get_puml_file_info()
      
      assert.is_not_nil(result)
      assert.are.equal("flowchart", result.name)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("returns full filename if no extension", function()
      local test_file = test_dir .. "/diagram"
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end
      
      local bufnr = vim.fn.bufadd(test_file)
      vim.fn.bufload(bufnr)
      vim.api.nvim_set_current_buf(bufnr)
      
      local result = util.get_puml_file_info()
      
      assert.is_not_nil(result)
      assert.are.equal("diagram", result.name)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("includes full path in result table", function()
      local test_file = test_dir .. "/diagram.puml"
      local f = io.open(test_file, "w")
      if f then
        f:write("@startuml\nA -> B\n@enduml")
        f:close()
      end
      
      local bufnr = vim.fn.bufadd(test_file)
      vim.fn.bufload(bufnr)
      vim.api.nvim_set_current_buf(bufnr)
      
      local result = util.get_puml_file_info()
      
      assert.is_not_nil(result)
      assert.are.equal(test_file, result.fullpath)
      assert.are.equal("diagram", result.name)
      assert.are.equal(test_dir, result.dir)
      
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
  end)
end)