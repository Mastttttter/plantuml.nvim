<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  Plugin Neovim để xem trước và xuất biểu đồ PlantUML với tính năng xem trước trên trình duyệt, xem trước ASCII theo thời gian thực và xuất PNG độ phân giải cao.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Giới thiệu

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

Plugin này cung cấp tích hợp PlantUML liền mạch cho Neovim với các tính năng sau:

- **Xem trước trên trình duyệt**: Tạo file SVG và xem trước trên trình duyệt mặc định thông qua máy chủ cục bộ
- **Xem trước ASCII theo thời gian thực**: Xem trước biểu đồ PlantUML dưới dạng nghệ thuật ASCII trong cửa sổ Neovim chia nhỏ bằng mục tiêu UTXT
- **Xuất PNG độ phân giải cao**: Xuất biểu đồ ra file PNG độ phân giải cao bằng Inkscape để có hình ảnh sắc nét, sẵn sàng cho xuất bản
- **Nhiều định dạng xuất**: Hỗ trợ tạo file SVG, PNG và UTXT (nghệ thuật ASCII)
- **Quản lý cửa sổ thông minh**: Tạo và cập nhật cửa sổ xem trước một cách tự động

## Cài đặt và Sử dụng

### Yêu cầu trước

- **Neovim** >= 0.8.0
- **Java** (bắt buộc nếu sử dụng plantuml.jar)
- **PlantUML** - một trong hai:
  - Lệnh `plantuml` có sẵn trong PATH, hoặc
  - File `plantuml.jar` (cấu hình đường dẫn trong phần thiết lập)
- **Inkscape** (tùy chọn, dùng để xuất PNG độ phân giải cao)
- **Node.js**

### Cấu hình loại file

Neovim không nhận diện đuôi file `.puml` và `.uml` theo mặc định. Ví dụ lazy.nvim bên dưới bao gồm phát hiện loại file thông qua hàm `init`. Ngoài ra, bạn có thể thêm đoạn sau vào `init.lua` (trước khi thiết lập lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Cài đặt

#### Sử dụng [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Tải khi mở file .puml hoặc .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Đường dẫn đến plantuml.jar (tùy chọn nếu plantuml có trong PATH)
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Xem trước PlantUML trên trình duyệt" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Xem trước PlantUML dạng ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Tạo file SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Tạo file PNG (độ phân giải cao)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Tạo file UTXT" },
  },
}
```

### Sử dụng

1. Mở file PlantUML (có đuôi `.puml` hoặc `.uml`) trong Neovim
2. Sử dụng các lệnh hoặc phím tắt bên dưới để xem trước hoặc xuất biểu đồ

### Lệnh và Phím tắt

| Lệnh | Phím tắt | Mô tả |
|------|----------|-------|
| `:PlantumlPreview` | `<leader>vup` | Tạo SVG và xem trước trên trình duyệt mặc định |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Tạo UTXT và xem trước trong cửa sổ chia nhỏ |
| `:PlantumlCreateSVG` | `<leader>vus` | Tạo file SVG trong thư mục `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Tạo file PNG độ phân giải cao (cần Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Tạo file UTXT (nghệ thuật ASCII) |

## Cấu hình

```lua
require('plantuml').setup({
  -- Đường dẫn đến lệnh java (mặc định: "java")
  java_cmd = "java",
  
  -- Đường dẫn đến file plantuml.jar (tùy chọn, sử dụng plantuml hệ thống nếu không đặt)
  plantuml_jar = nil,
  
  -- Đường dẫn đến lệnh inkscape (mặc định: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Cổng máy chủ cho xem trước trên trình duyệt (mặc định: 8912)
  server_port = 8912,
  
  -- DPI cho xuất PNG qua Inkscape (mặc định: 800)
  png_dpi = 800,
})
```

### Tùy chọn cấu hình

| Tùy chọn | Kiểu | Mặc định | Mô tả |
|----------|------|----------|-------|
| `java_cmd` | string | `"java"` | Đường dẫn đến file thực thi Java (dùng với `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Đường dẫn đến file `plantuml.jar`. Nếu `nil`, sử dụng lệnh `plantuml` của hệ thống |
| `inkscape_cmd` | string | `"inkscape"` | Đường dẫn đến file thực thi Inkscape để chuyển đổi PNG |
| `server_port` | number | `8912` | Cổng cho máy chủ xem trước cục bộ |
| `png_dpi` | number | `800` | Độ phân giải DPI cho xuất PNG |

## Lưu ý

- **File tạm**: Tất cả file tạm được lưu trong `/tmp/plantuml.nvim/`
- **Xem trước trên trình duyệt**: Xem trước SVG chạy một máy chủ HTTP cục bộ để phục vụ các file đã tạo
- **File xuất**: Các lệnh `PlantumlCreate*` lưu file vào `<thư-mục-dự-án>/umlout/`:
  - Plugin xác định thư mục dự án bằng cách tìm thư mục cha đầu tiên chứa `.git`
  - Nếu không tìm thấy `.git`, thư mục làm việc hiện tại của buffer sẽ được sử dụng
- **Quản lý cửa sổ thông minh**: `PlantumlPreviewUTXT` quản lý cửa sổ xem trước một cách tự động:
  - Tạo cửa sổ chia nhỏ mới nếu chưa có cửa sổ xem trước
  - Cập nhật buffer hiện có nếu cửa sổ xem trước đã mở
- **Lệnh Inkscape**: Tạo PNG sử dụng Inkscape với mẫu lệnh sau:

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## Giấy phép

MIT License

## Một sự thật thú vị

Dự án này là lần thử nghiệm đầu tiên của tôi sử dụng `OpenCode`, ngay cả phần lớn [README.md](./README.md) này. Phần duy nhất hoàn toàn do tôi tự hoàn thành là [README_FOR_AGENT.md](./README_FOR_AGENT.md).
