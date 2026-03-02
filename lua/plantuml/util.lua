--- Utility module for plantuml.nvim
--- Provides path manipulation, git root detection, and temp directory management

local M = {}

local uv = vim.loop

--- Find the git root directory by walking up the directory tree
--- @param buffer_path string|nil The starting path to search from
--- @return string|nil The git root directory path, or nil if not found
function M.find_git_root(buffer_path)
  -- Handle nil or empty input
  if not buffer_path or buffer_path == "" then
    return nil
  end

  -- Resolve to absolute path
  local path = vim.fn.fnamemodify(buffer_path, ":p")
  
  -- Remove trailing slash for consistency
  path = path:gsub("/$", "")
  
  -- Walk up the directory tree
  while path ~= "" and path ~= "/" do
    -- Check if .git exists (as file or directory)
    local git_path = path .. "/.git"
    local stat = uv.fs_stat(git_path)
    
    if stat then
      return path
    end
    
    -- Move to parent directory
    path = vim.fn.fnamemodify(path, ":h")
  end
  
  return nil
end

--- Get the project folder (git root or cwd)
--- @param buffer_path string|nil The buffer path to search from
--- @return string The project folder path
function M.get_project_folder(buffer_path)
  -- Try to find git root first
  local git_root = M.find_git_root(buffer_path)
  
  if git_root then
    return git_root
  end
  
  -- Fallback to current working directory
  return uv.cwd()
end

--- Ensure the temp directory exists
--- @return string|nil The temp directory path, or nil on failure
function M.ensure_temp_dir()
  local temp_path = "/tmp/plantuml.nvim"
  
  -- Check if it already exists
  local stat = uv.fs_stat(temp_path)
  if stat then
    return temp_path
  end
  
  -- Create with 0700 permissions (rwx for owner only)
  local ok, err = uv.fs_mkdir(temp_path, 448) -- 0700 in octal = 448 decimal
  if not ok then
    vim.notify("plantuml.nvim: Failed to create temp directory: " .. err, vim.log.levels.ERROR)
    return nil
  end
  
  return temp_path
end

--- Get the output directory path
--- @param buffer_path string|nil The buffer path to determine project folder
--- @param subdir string|nil The subdirectory name (e.g., "svg", "png", "utxt")
--- @return string The output directory path
function M.get_output_dir(buffer_path, subdir)
  local project_folder = M.get_project_folder(buffer_path)
  local output_dir = project_folder .. "/umlout"
  
  if subdir then
    output_dir = output_dir .. "/" .. subdir
  else
    output_dir = output_dir .. "/"
  end
  
  return output_dir
end

--- Get information about the current PlantUML file
--- @return table|nil Table with name (without extension), fullpath, dir; or nil if no buffer
function M.get_puml_file_info()
  -- Get current buffer
  local bufnr = vim.api.nvim_get_current_buf()
  if bufnr == 0 then
    return nil
  end
  
  -- Get buffer name (full path)
  local fullpath = vim.api.nvim_buf_get_name(bufnr)
  if fullpath == "" then
    return nil
  end
  
  -- Extract directory and filename
  local dir = vim.fn.fnamemodify(fullpath, ":h")
  local filename = vim.fn.fnamemodify(fullpath, ":t")
  
  -- Remove extension if present (.puml or .uml)
  local name = filename:gsub("%.puml$", "")
  name = name:gsub("%.uml$", "")
  
  -- If no recognized extension was removed, name equals filename
  -- but we already have the right value
  
  return {
    name = name,
    fullpath = fullpath,
    dir = dir,
    filename = filename,
  }
end

return M