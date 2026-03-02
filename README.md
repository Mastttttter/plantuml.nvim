<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  A Neovim plugin for previewing and exporting PlantUML diagrams with browser preview, real-time ASCII preview, and high-DPI PNG export.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./i18n/README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./i18n/README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./i18n/README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./i18n/README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./i18n/README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./i18n/README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./i18n/README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./i18n/README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./i18n/README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./i18n/README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./i18n/README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./i18n/README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./i18n/README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./i18n/README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./i18n/README.vi.md)

## Introduction

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Feature 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Feature 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

This plugin provides seamless PlantUML integration for Neovim with the following features:

- **Browser Preview**: Generate SVG files and preview them in your default browser via a local server
- **Real-time ASCII Preview**: Preview PlantUML diagrams as ASCII art in a split Neovim window using the UTXT target
- **High-DPI PNG Export**: Export diagrams to high-resolution PNG files using Inkscape for crisp, publication-ready images
- **Multiple Export Formats**: Support for SVG, PNG, and UTXT (ASCII art) file generation
- **Smart Window Management**: Intelligent preview window creation and updates

## Installation & Usage

### Prerequisites

- **Neovim** >= 0.8.0
- **Java** (required if using plantuml.jar)
- **PlantUML** - either:
  - `plantuml` command available in PATH, or
  - `plantuml.jar` file (configure path in setup)
- **Inkscape** (optional, for high-DPI PNG export)

### Filetype Configuration

Neovim does not recognize `.puml` and `.uml` file extensions by default. The lazy.nvim example below includes filetype detection via `init` function. Alternatively, you can add this to your `init.lua` (before lazy.nvim setup):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Installation

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Lazy load when opening .puml or .uml files
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Path to plantuml.jar (optional if plantuml is in PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Preview PlantUML in browser" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Preview PlantUML as ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Create SVG file" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Create PNG file (high-DPI)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Create UTXT file" },
  },
}
```

### Usage

1. Open a PlantUML file (`.puml` or `.uml` extension) in Neovim
2. Use the commands or keybindings below to preview or export your diagram

### Commands & Keybindings

| Command | Keybinding | Description |
|---------|------------|-------------|
| `:PlantumlPreview` | `<leader>vup` | Generate SVG and preview in default browser |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Generate UTXT and preview in a split window |
| `:PlantumlCreateSVG` | `<leader>vus` | Create SVG file in `umlout/` directory |
| `:PlantumlCreatePNG` | `<leader>vug` | Create high-DPI PNG file (requires Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Create UTXT (ASCII art) file |

## Configuration

```lua
require('plantuml').setup({
  -- Path to java command (default: "java")
  java_cmd = "java",
  
  -- Path to plantuml.jar file (optional, uses system plantuml if not set)
  plantuml_jar = nil,
  
  -- Path to inkscape command (default: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Server port for browser preview (default: 8080)
  server_port = 8080,
  
  -- DPI for PNG export via Inkscape (default: 300)
  png_dpi = 300,
})
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `java_cmd` | string | `"java"` | Path to Java executable (used with `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Path to `plantuml.jar` file. If `nil`, uses system `plantuml` command |
| `inkscape_cmd` | string | `"inkscape"` | Path to Inkscape executable for PNG conversion |
| `server_port` | number | `8080` | Port for local preview server |
| `png_dpi` | number | `300` | DPI resolution for PNG export |

## Notes

- **Temporary Files**: All temporary files are stored in `/tmp/plantuml.nvim/`
- **Browser Preview**: SVG preview runs a local HTTP server to serve the generated files
- **Output Files**: The `PlantumlCreate*` commands save files to `<project-folder>/umlout/`:
  - The plugin detects the project folder by finding the first parent directory containing `.git`
  - If no `.git` is found, the buffer's current working directory is used
- **Smart Window Management**: `PlantumlPreviewUTXT` intelligently manages the preview window:
  - Creates a new split window if no preview window exists
  - Updates the existing buffer if a preview window is already open
- **Inkscape Command**: PNG generation uses Inkscape with the following command pattern:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## License

MIT License

## An incredible fact

This project is my first try using `OpenCode`, even most of this [README.md](./README.md). The only part purely finished by myself is [README_FOR_AGENT.md](./README_FOR_AGENT.md).
