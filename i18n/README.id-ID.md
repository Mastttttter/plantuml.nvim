<h1 align="center"> ✨ plantuml.nvim untuk Neovim ✨ </h1>

<p align="center">
  Plugin Neovim untuk melihat pratinjau dan mengekspor diagram PlantUML dengan pratinjau di browser, pratinjau ASCII secara real-time, dan ekspor PNG resolusi tinggi.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Pengantar

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Fitur 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Fitur 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Plugin ini menyediakan integrasi PlantUML yang mulus untuk Neovim dengan fitur-fitur berikut:

- **Pratinjau di Browser**: Menghasilkan file SVG dan menampilkannya di browser default melalui server lokal
- **Pratinjau ASCII Real-time**: Menampilkan diagram PlantUML sebagai seni ASCII di jendela Neovim terpisah menggunakan target UTXT
- **Ekspor PNG Resolusi Tinggi**: Mengekspor diagram ke file PNG beresolusi tinggi menggunakan Inkscape untuk gambar yang tajam dan siap publikasi
- **Berbagai Format Ekspor**: Mendukung pembuatan file SVG, PNG, dan UTXT (seni ASCII)
- **Pengelolaan Jendela Cerdas**: Pembuatan dan pembaruan jendela pratinjau secara cerdas

## Instalasi & Penggunaan

### Prasyarat

- **Neovim** >= 0.8.0
- **Java** (diperlukan jika menggunakan plantuml.jar)
- **PlantUML** - salah satu dari:
  - perintah `plantuml` tersedia di PATH, atau
  - file `plantuml.jar` (konfigurasikan path saat setup)
- **Inkscape** (opsional, untuk ekspor PNG resolusi tinggi)
- **Node.js**

### Konfigurasi Tipe File

Neovim tidak mengenali ekstensi file `.puml` dan `.uml` secara default. Contoh lazy.nvim di bawah ini menyertakan deteksi tipe file melalui fungsi `init`. Sebagai alternatif, Anda bisa menambahkan ini ke `init.lua` Anda (sebelum setup lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Instalasi

#### Menggunakan [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Lazy load saat membuka file .puml atau .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Path ke plantuml.jar (opsional jika plantuml ada di PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Pratinjau PlantUML di browser" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Pratinjau PlantUML sebagai ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Buat file SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Buat file PNG (resolusi tinggi)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Buat file UTXT" },
  },
}
```

### Penggunaan

1. Buka file PlantUML (ekstensi `.puml` atau `.uml`) di Neovim
2. Gunakan perintah atau keybinding di bawah untuk melihat pratinjau atau mengekspor diagram Anda

### Perintah & Keybinding

| Perintah | Keybinding | Keterangan |
|----------|------------|------------|
| `:PlantumlPreview` | `<leader>vup` | Membuat SVG dan membuka pratinjau di browser default |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Membuat UTXT dan menampilkan pratinjau di jendela terpisah |
| `:PlantumlCreateSVG` | `<leader>vus` | Membuat file SVG di direktori `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Membuat file PNG resolusi tinggi (memerlukan Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Membuat file UTXT (seni ASCII) |

## Konfigurasi

```lua
require('plantuml').setup({
  -- Path ke perintah java (default: "java")
  java_cmd = "java",
  
  -- Path ke file plantuml.jar (opsional, menggunakan plantuml sistem jika tidak diatur)
  plantuml_jar = nil,
  
  -- Path ke perintah inkscape (default: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Port server untuk pratinjau browser (default: 8080)
  server_port = 8080,
  
  -- DPI untuk ekspor PNG melalui Inkscape (default: 300)
  png_dpi = 300,
})
```

### Opsi Konfigurasi

| Opsi | Tipe | Default | Keterangan |
|------|------|---------|------------|
| `java_cmd` | string | `"java"` | Path ke executable Java (digunakan dengan `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Path ke file `plantuml.jar`. Jika `nil`, menggunakan perintah `plantuml` sistem |
| `inkscape_cmd` | string | `"inkscape"` | Path ke executable Inkscape untuk konversi PNG |
| `server_port` | number | `8080` | Port untuk server pratinjau lokal |
| `png_dpi` | number | `300` | Resolusi DPI untuk ekspor PNG |

## Catatan

- **File Sementara**: Semua file sementara disimpan di `/tmp/plantuml.nvim/`
- **Pratinjau Browser**: Pratinjau SVG menjalankan server HTTP lokal untuk menyajikan file yang dihasilkan
- **File Output**: Perintah `PlantumlCreate*` menyimpan file ke `<folder-proyek>/umlout/`:
  - Plugin mendeteksi folder proyek dengan mencari direktori induk pertama yang berisi `.git`
  - Jika `.git` tidak ditemukan, direktori kerja saat ini dari buffer akan digunakan
- **Pengelolaan Jendela Cerdas**: `PlantumlPreviewUTXT` mengelola jendela pratinjau secara cerdas:
  - Membuat jendela split baru jika belum ada jendela pratinjau
  - Memperbarui buffer yang ada jika jendela pratinjau sudah terbuka
- **Perintah Inkscape**: Pembuatan PNG menggunakan Inkscape dengan pola perintah berikut:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Lisensi

Lisensi MIT

## Fakta Menarik

Proyek ini adalah percobaan pertama saya menggunakan `OpenCode`, bahkan sebagian besar [README.md](./README.md) ini. Satu-satunya bagian yang saya kerjakan sendiri adalah [README_FOR_AGENT.md](./README_FOR_AGENT.md).
