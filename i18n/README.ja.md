<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  Neovim用PlantUMLプラグイン - ブラウザプレビュー、リアルタイムASCIIプレビュー、高解像度PNG出力に対応
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## はじめに

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

このプラグインは、NeovimでのPlantUML統合をシームレスに提供します。以下の機能を備えています：

- **ブラウザプレビュー**: SVGファイルを生成し、ローカルサーバー経由でデフォルトブラウザでプレビュー
- **リアルタイムASCIIプレビュー**: UTXTターゲットを使用して、Neovimの分割ウィンドウでPlantUML図をアスキーアートとしてプレビュー
- **高解像度PNG出力**: Inkscapeを使用して、出版物にも対応できる鮮明な高解像度PNGファイルを出力
- **複数の出力フォーマット**: SVG、PNG、UTXT（アスキーアート）ファイルの生成に対応
- **スマートウィンドウ管理**: プレビューウィンドウの作成と更新を自動管理

## インストールと使い方

### 前提条件

- **Neovim** >= 0.8.0
- **Java** （plantuml.jarを使用する場合に必要）
- **PlantUML** - 以下のいずれか：
  - `plantuml`コマンドがPATHで利用可能、または
  - `plantuml.jar`ファイル（セットアップでパスを設定）
- **Inkscape** （オプション、高解像度PNG出力用）

### ファイルタイプの設定

Neovimはデフォルトで`.puml`と`.uml`ファイル拡張子を認識しません。下記のlazy.nvimの例では、`init`関数でファイルタイプ検出を設定しています。または、`init.lua`に以下を追加してください（lazy.nvimのセットアップより前）：

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### インストール

#### [lazy.nvim](https://github.com/folke/lazy.nvim)を使用する場合

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
  ft = { "plantuml" },  -- .pumlまたは.umlファイルを開いた時に遅延読み込み
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- plantuml.jarへのパス（plantumlがPATHにある場合はオプション）
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "PlantUMLをブラウザでプレビュー" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "PlantUMLをASCIIでプレビュー" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "SVGファイルを作成" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "高解像度PNGファイルを作成" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "UTXTファイルを作成" },
  },
}
```

### 使い方

1. NeovimでPlantUMLファイル（`.puml`または`.uml`拡張子）を開く
2. 以下のコマンドまたはキーバインドを使用して、図をプレビューまたは出力

### コマンドとキーバインド

| コマンド | キーバインド | 説明 |
|---------|------------|------|
| `:PlantumlPreview` | `<leader>vup` | SVGを生成してデフォルトブラウザでプレビュー |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | UTXTを生成して分割ウィンドウでプレビュー |
| `:PlantumlCreateSVG` | `<leader>vus` | `umlout/`ディレクトリにSVGファイルを作成 |
| `:PlantumlCreatePNG` | `<leader>vug` | 高解像度PNGファイルを作成（Inkscapeが必要） |
| `:PlantumlCreateUTXT` | `<leader>vut` | UTXT（アスキーアート）ファイルを作成 |

## 設定

```lua
require('plantuml').setup({
  -- Javaコマンドへのパス（デフォルト: "java"）
  java_cmd = "java",
  
  -- plantuml.jarファイルへのパス（オプション、未設定の場合はシステムのplantumlを使用）
  plantuml_jar = nil,
  
  -- Inkscapeコマンドへのパス（デフォルト: "inkscape"）
  inkscape_cmd = "inkscape",
  
  -- ブラウザプレビュー用のサーバーポート（デフォルト: 8080）
  server_port = 8080,
  
  -- Inkscape経由のPNG出力のDPI（デフォルト: 300）
  png_dpi = 300,
})
```

### 設定オプション

| オプション | 型 | デフォルト | 説明 |
|--------|------|---------|------|
| `java_cmd` | string | `"java"` | Java実行ファイルへのパス（`plantuml_jar`使用時に使用） |
| `plantuml_jar` | string \| nil | `nil` | `plantuml.jar`ファイルへのパス。`nil`の場合、システムの`plantuml`コマンドを使用 |
| `inkscape_cmd` | string | `"inkscape"` | PNG変換用のInkscape実行ファイルへのパス |
| `server_port` | number | `8080` | ローカルプレビューサーバーのポート番号 |
| `png_dpi` | number | `300` | PNG出力のDPI解像度 |

## 注意事項

- **一時ファイル**: すべての一時ファイルは`/tmp/plantuml.nvim/`に保存されます
- **ブラウザプレビュー**: SVGプレビューは、生成されたファイルを配信するためにローカルHTTPサーバーを実行します
- **出力ファイル**: `PlantumlCreate*`コマンドは`<プロジェクトフォルダ>/umlout/`にファイルを保存します：
  - プラグインは`.git`を含む最初の親ディレクトリを検索してプロジェクトフォルダを特定します
  - `.git`が見つからない場合、バッファのカレントワーキングディレクトリが使用されます
- **スマートウィンドウ管理**: `PlantumlPreviewUTXT`はプレビューウィンドウを自動管理します：
  - プレビューウィンドウが存在しない場合は新しい分割ウィンドウを作成
  - プレビューウィンドウが既に開いている場合は既存のバッファを更新
- **Inkscapeコマンド**: PNG生成は以下のコマンドパターンでInkscapeを使用します：

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## ライセンス

MIT License

## 興味深い事実

このプロジェクトは`OpenCode`を使った私の最初の試みであり、この[README.md](./README.md)の大部分も同様です。純粋に私自身で完成させた唯一の部分は[README_FOR_AGENT.md](./README_FOR_AGENT.md)です。
