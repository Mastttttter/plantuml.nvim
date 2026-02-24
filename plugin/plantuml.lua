-- 自动加载的命令定义
vim.api.nvim_create_user_command("PlantumlPreviewtutxt", function()
	require("plantuml").run()
end, {
	desc = "生成 PlantUML 文本预览并右分屏显示",
	nargs = 0,
})
