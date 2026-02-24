local M = {}

-- 配置默认值
M.config = {
	output_dir = "/tmp",
	suffix = "_tutxt",
	plantuml_cmd = "plantuml",
}

-- 初始化配置
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- 获取当前缓冲区的绝对路径
local function get_current_file_path()
	local path = vim.fn.expand("%:p")
	if path == "" then
		vim.notify("当前文件未保存，请先保存文件！", vim.log.levels.WARN)
		return nil
	end
	return path
end

-- 构建输出文件路径 /tmp/XXX_tutxt
local function get_output_path(input_path)
	local filename_no_ext = vim.fn.fnamemodify(input_path, ":t:r") -- 获取不带扩展名的文件名
	return M.config.output_dir .. "/" .. filename_no_ext .. M.config.suffix
end

-- 查找是否已有窗口显示该文件
local function find_window_by_buffer_name(filepath)
	for _, win_id in ipairs(vim.api.nvim_list_wins()) do
		local buf_id = vim.api.nvim_win_get_buf(win_id)
		local buf_name = vim.api.nvim_buf_get_name(buf_id)
		if buf_name == filepath then
			return win_id, buf_id
		end
	end
	return nil, nil
end

-- 打开或更新预览窗口
local function open_preview_window(filepath)
	-- 检查文件是否存在 (plantuml 生成可能需要极短时间，确保已生成)
	if vim.fn.filereadable(filepath) == 0 then
		vim.notify("预览文件生成失败：" .. filepath, vim.log.levels.ERROR)
		return
	end

	local win_id, buf_id = find_window_by_buffer_name(filepath)

	if win_id then
		-- 如果窗口已存在，聚焦该窗口并强制重新加载内容
		vim.api.nvim_set_current_win(win_id)
		vim.cmd("edit!")
		vim.notify("预览已更新", vim.log.levels.INFO)
	else
		-- 如果不存在，向右分屏打开
		-- rightbelow vsplit 确保在右侧打开
		vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(filepath))
		vim.notify("预览窗口已创建", vim.log.levels.INFO)
	end

	-- 可选：设置预览窗口为只读，防止误编辑
	vim.opt_local.readonly = true
	vim.opt_local.modifiable = false
end

-- 执行 PlantUML 命令
function M.run()
	local input_path = get_current_file_path()
	if not input_path then
		return
	end

	-- 简单的后缀检查，可选
	if not input_path:match("%.puml$") then
		vim.notify("警告：当前文件不是 .puml 文件", vim.log.levels.WARN)
	end

	local output_path = get_output_path(input_path)

	-- 构建命令：plantuml -tutxt -o /tmp/XXX_tutxt /absolute/path/XXX.puml
	local cmd = {
		M.config.plantuml_cmd,
		"-tutxt",
		"-o",
		output_path,
		input_path,
	}

	vim.notify("正在生成预览...", vim.log.levels.INFO)

	-- 使用 jobstart 异步执行，避免卡住 UI
	vim.fn.jobstart(cmd, {
		on_exit = function(job_id, exit_code, event)
			if exit_code == 0 then
				-- 执行成功后，在主线程中打开窗口
				vim.schedule(function()
					open_preview_window(output_path)
				end)
			else
				vim.schedule(function()
					vim.notify("PlantUML 命令执行失败 (Exit Code: " .. exit_code .. ")", vim.log.levels.ERROR)
				end)
			end
		end,
		stderr_buffered = true,
		stdout_buffered = true,
	})
end

return M
