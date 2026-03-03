<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  一款用于预览和导出 PlantUML 图表的 Neovim 插件，支持浏览器预览、实时 ASCII 预览和高 DPI PNG 导出。
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## 简介

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="功能展示 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="功能展示 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

本插件为 Neovim 提供了无缝的 PlantUML 集成，具有以下功能：

- **浏览器预览**：生成 SVG 文件并通过本地服务器在默认浏览器中预览
- **实时 ASCII 预览**：使用 UTXT 目标在 Neovim 分栏窗口中以 ASCII 字符画形式预览 PlantUML 图表
- **高 DPI PNG 导出**：使用 Inkscape 将图表导出为高分辨率 PNG 文件，获得清晰、适合出版的图像
- **多种导出格式**：支持生成 SVG、PNG 和 UTXT（ASCII 字符画）文件
- **智能窗口管理**：智能创建和更新预览窗口

## 安装与使用

### 前置要求

- **Neovim** >= 0.8.0
- **Java**（使用 plantuml.jar 时需要）
- **PlantUML** - 以下任一方式：
  - `plantuml` 命令已添加到 PATH 环境变量，或
  - `plantuml.jar` 文件（在 setup 中配置路径）
- **Inkscape**（可选，用于高 DPI PNG 导出）
- **Node.js**

### 文件类型配置

Neovim 默认不识别 `.puml` 和 `.uml` 文件扩展名。下方的 lazy.nvim 示例通过 `init` 函数包含了文件类型检测。或者，你可以在 `init.lua` 中添加以下内容（在 lazy.nvim setup 之前）：

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### 安装

#### 使用 [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  "Mastttttter/plantuml.nvim",
  init = function()
    vim.filetype.add({
      extension = {
        puml = "plantuml",
        uml = "plantuml",
      },
    })
  end,
  ft = { "plantuml" },  -- 打开 .puml 或 .uml 文件时延迟加载
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- plantuml.jar 路径（如果 plantuml 在 PATH 中则可选）
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "在浏览器中预览 PlantUML" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "以 ASCII 形式预览 PlantUML" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "创建 SVG 文件" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "创建 PNG 文件（高 DPI）" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "创建 UTXT 文件" },
  },
}
```

### 使用方法

1. 在 Neovim 中打开 PlantUML 文件（扩展名为 `.puml` 或 `.uml`）
2. 使用下方命令或快捷键预览或导出图表

### 命令与快捷键

| 命令 | 快捷键 | 说明 |
|---------|------------|-------------|
| `:PlantumlPreview` | `<leader>vup` | 生成 SVG 并在默认浏览器中预览 |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | 生成 UTXT 并在分栏窗口中预览 |
| `:PlantumlCreateSVG` | `<leader>vus` | 在 `umlout/` 目录下创建 SVG 文件 |
| `:PlantumlCreatePNG` | `<leader>vug` | 创建高 DPI PNG 文件（需要 Inkscape） |
| `:PlantumlCreateUTXT` | `<leader>vut` | 创建 UTXT（ASCII 字符画）文件 |

## 配置

```lua
require('plantuml').setup({
  -- Java 命令路径（默认值："java"）
  java_cmd = "java",
  
  -- plantuml.jar 文件路径（可选，如未设置则使用系统 plantuml 命令）
  plantuml_jar = nil,
  
  -- Inkscape 命令路径（默认值："inkscape"）
  inkscape_cmd = "inkscape",
  
  -- 浏览器预览服务器端口（默认值：8912）
  server_port = 8912,
  
  -- 通过 Inkscape 导出 PNG 的 DPI（默认值：800）
  png_dpi = 800,
})
```

### 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|--------|------|---------|-------------|
| `java_cmd` | string | `"java"` | Java 可执行文件路径（配合 `plantuml_jar` 使用） |
| `plantuml_jar` | string \| nil | `nil` | `plantuml.jar` 文件路径。如果为 `nil`，则使用系统 `plantuml` 命令 |
| `inkscape_cmd` | string | `"inkscape"` | 用于 PNG 转换的 Inkscape 可执行文件路径 |
| `server_port` | number | `8912` | 本地预览服务器端口 |
| `png_dpi` | number | `800` | PNG 导出的 DPI 分辨率 |

## 注意事项

- **临时文件**：所有临时文件存储在 `/tmp/plantuml.nvim/` 目录
- **浏览器预览**：SVG 预览会启动一个本地 HTTP 服务器来提供生成的文件
- **输出文件**：`PlantumlCreate*` 命令将文件保存到 `<项目目录>/umlout/`：
  - 插件通过查找第一个包含 `.git` 的父目录来检测项目目录
  - 如果未找到 `.git`，则使用缓冲区的当前工作目录
- **智能窗口管理**：`PlantumlPreviewUTXT` 智能管理预览窗口：
  - 如果预览窗口不存在，则创建新的分栏窗口
  - 如果预览窗口已打开，则更新现有缓冲区
- **Inkscape 命令**：PNG 生成使用 Inkscape，命令格式如下：

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## 许可证

MIT License

## 一个有趣的事实

这个项目是我第一次尝试使用 `OpenCode`，甚至大部分 [README.md](../README.md) 也是由它完成的。唯一完全由我自己完成的部分是 [README_FOR_AGENT.md](../README_FOR_AGENT.md)。
