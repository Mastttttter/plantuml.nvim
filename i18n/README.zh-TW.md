<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  Neovim 外掛，提供 PlantUML 圖表預覽與匯出功能，支援瀏覽器預覽、即時 ASCII 預覽以及高解析度 PNG 匯出。
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./i18n/README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./i18n/README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./i18n/README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./i18n/README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./i18n/README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./i18n/README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./i18n/README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./i18n/README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./i18n/README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./i18n/README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./i18n/README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./i18n/README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./i18n/README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./i18n/README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./i18n/README.vi.md)

## 簡介

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

此外掛為 Neovim 提供無縫的 PlantUML 整合功能，具備以下特性：

- **瀏覽器預覽**：透過本機伺服器產生 SVG 檔案，並在預設瀏覽器中預覽
- **即時 ASCII 預覽**：使用 UTXT 格式在 Neovim 分割視窗中即時預覽 PlantUML 圖表
- **高解析度 PNG 匯出**：使用 Inkscape 將圖表匯出為高解析度 PNG 檔案，適合出版用途
- **多種匯出格式**：支援產生 SVG、PNG 及 UTXT（ASCII 藝術）檔案
- **智慧視窗管理**：智能管理預覽視窗的建立與更新

## 安裝與使用

### 前置需求

- **Neovim** >= 0.8.0
- **Java**（使用 plantuml.jar 時必要）
- **PlantUML** - 擇一即可：
  - `plantuml` 指令已存在於 PATH 環境變數中，或
  - `plantuml.jar` 檔案（需在設定中指定路徑）
- **Inkscape**（選用，用於高解析度 PNG 匯出）

### 檔案類型設定

Neovim 預設無法識別 `.puml` 與 `.uml` 副檔名。下方的 lazy.nvim 設定範例已透過 `init` 函式包含檔案類型偵測。或者，您可以將以下設定加入 `init.lua`（需在 lazy.nvim 設定之前）：

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### 安裝

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
  ft = { "plantuml" },  -- 開啟 .puml 或 .uml 檔案時延遲載入
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- plantuml.jar 路徑（若 plantuml 已在 PATH 中則可省略）
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "在瀏覽器中預覽 PlantUML" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "以 ASCII 預覽 PlantUML" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "建立 SVG 檔案" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "建立 PNG 檔案（高解析度）" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "建立 UTXT 檔案" },
  },
}
```

### 使用方式

1. 在 Neovim 中開啟 PlantUML 檔案（副檔名為 `.puml` 或 `.uml`）
2. 使用下方指令或快速鍵來預覽或匯出圖表

### 指令與快速鍵

| 指令 | 快速鍵 | 說明 |
|------|--------|------|
| `:PlantumlPreview` | `<leader>vup` | 產生 SVG 並在預設瀏覽器中預覽 |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | 產生 UTXT 並在分割視窗中預覽 |
| `:PlantumlCreateSVG` | `<leader>vus` | 在 `umlout/` 目錄中建立 SVG 檔案 |
| `:PlantumlCreatePNG` | `<leader>vug` | 建立高解析度 PNG 檔案（需要 Inkscape） |
| `:PlantumlCreateUTXT` | `<leader>vut` | 建立 UTXT（ASCII 藝術）檔案 |

## 設定

```lua
require('plantuml').setup({
  -- Java 指令路徑（預設值："java"）
  java_cmd = "java",
  
  -- plantuml.jar 檔案路徑（選用，若未設定則使用系統 plantuml 指令）
  plantuml_jar = nil,
  
  -- Inkscape 指令路徑（預設值："inkscape"）
  inkscape_cmd = "inkscape",
  
  -- 瀏覽器預覽伺服器通訊埠（預設值：8080）
  server_port = 8080,
  
  -- 透過 Inkscape 匯出 PNG 的 DPI（預設值：300）
  png_dpi = 300,
})
```

### 設定選項

| 選項 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `java_cmd` | string | `"java"` | Java 執行檔路徑（與 `plantuml_jar` 搭配使用） |
| `plantuml_jar` | string \| nil | `nil` | `plantuml.jar` 檔案路徑。若為 `nil`，則使用系統 `plantuml` 指令 |
| `inkscape_cmd` | string | `"inkscape"` | Inkscape 執行檔路徑，用於 PNG 轉換 |
| `server_port` | number | `8080` | 本機預覽伺服器的通訊埠 |
| `png_dpi` | number | `300` | PNG 匯出的 DPI 解析度 |

## 注意事項

- **暫存檔案**：所有暫存檔案儲存於 `/tmp/plantuml.nvim/`
- **瀏覽器預覽**：SVG 預覽會啟動本機 HTTP 伺服器來提供產生的檔案
- **輸出檔案**：`PlantumlCreate*` 指令會將檔案儲存至 `<專案資料夾>/umlout/`：
  - 外掛會透過尋找第一個包含 `.git` 的上層目錄來偵測專案資料夾
  - 若找不到 `.git`，則使用緩衝區的目前工作目錄
- **智慧視窗管理**：`PlantumlPreviewUTXT` 會智慧管理預覽視窗：
  - 若預覽視窗不存在，會建立新的分割視窗
  - 若預覽視窗已開啟，會更新現有緩衝區內容
- **Inkscape 指令**：PNG 產生使用 Inkscape，指令格式如下：

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## 授權條款

MIT License

## 驚人的事實

本專案是我首次使用 `OpenCode` 的嘗試，甚至大部分的 [README.md](../README.md) 也是如此。唯一完全由我自己完成的部分是 [README_FOR_AGENT.md](../README_FOR_AGENT.md)。