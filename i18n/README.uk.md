<h1 align="center"> ✨ plantuml.nvim для Neovim ✨ </h1>

<p align="center">
  Плагін для Neovim для перегляду та експорту діаграм PlantUML з попереднім переглядом у браузері, переглядом у реальному часі у форматі ASCII та експортом у PNG високої роздільної здатності.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Вступ

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Функція 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Функція 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Цей плагін забезпечує безшовну інтеграцію PlantUML для Neovim з наступними можливостями:

- **Перегляд у браузері**: генерація SVG-файлів та їх перегляд у браузері за замовчуванням через локальний сервер
- **Перегляд ASCII у реальному часі**: перегляд діаграм PlantUML у форматі ASCII-графіки у розділеному вікні Neovim з використанням формату UTXT
- **Експорт у PNG високої роздільної здатності**: експорт діаграм у високоякісні PNG-файли за допомогою Inkscape для чітких зображень, готових до публікації
- **Підтримка кількох форматів експорту**: генерація файлів у форматах SVG, PNG та UTXT (ASCII-графіка)
- **Розумне керування вікнами**: інтелектуальне створення та оновлення вікон попереднього перегляду

## Встановлення та використання

### Системні вимоги

- **Neovim** >= 0.8.0
- **Java** (потрібна при використанні plantuml.jar)
- **PlantUML** - одне з наступного:
  - команда `plantuml` доступна у PATH, або
  - файл `plantuml.jar` (налаштувати шлях у конфігурації)
- **Inkscape** (опціонально, для експорту у PNG високої роздільної здатності)
- **Node.js**

### Налаштування типу файлів

Neovim за замовчуванням не розпізнає розширення файлів `.puml` та `.uml`. Наведений нижче приклад для lazy.nvim включає визначення типу файлів через функцію `init`. Альтернативно ви можете додати це до вашого `init.lua` (перед налаштуванням lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Встановлення

#### За допомогою [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Відкладене завантаження при відкритті файлів .puml або .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Шлях до plantuml.jar (опціонально, якщо plantuml у PATH)
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Попередній перегляд PlantUML у браузері" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Попередній перегляд PlantUML як ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Створити файл SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Створити файл PNG (висока роздільна здатність)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Створити файл UTXT" },
  },
}
```

### Використання

1. Відкрийте файл PlantUML (з розширенням `.puml` або `.uml`) у Neovim
2. Використовуйте команди або клавіатурні скорочення нижче для попереднього перегляду або експорту вашої діаграми

### Команди та клавіатурні скорочення

| Команда | Клавіатурне скорочення | Опис |
|---------|------------------------|------|
| `:PlantumlPreview` | `<leader>vup` | Генерує SVG та відкриває попередній перегляд у браузері за замовчуванням |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Генерує UTXT та показує у розділеному вікні |
| `:PlantumlCreateSVG` | `<leader>vus` | Створює файл SVG у директорії `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Створює файл PNG високої роздільної здатності (потребує Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Створює файл UTXT (ASCII-графіка) |

## Конфігурація

```lua
require('plantuml').setup({
  -- Шлях до команди java (за замовчуванням: "java")
  java_cmd = "java",
  
  -- Шлях до файлу plantuml.jar (опціонально, використовується системний plantuml, якщо не задано)
  plantuml_jar = nil,
  
  -- Шлях до команди inkscape (за замовчуванням: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Порт сервера для попереднього перегляду у браузері (за замовчуванням: 8912)
  server_port = 8912,
  
  -- DPI для експорту PNG через Inkscape (за замовчуванням: 800)
  png_dpi = 800,
})
```

### Параметри конфігурації

| Параметр | Тип | За замовчуванням | Опис |
|----------|-----|------------------|------|
| `java_cmd` | string | `"java"` | Шлях до виконуваного файлу Java (використовується з `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Шлях до файлу `plantuml.jar`. Якщо `nil`, використовується системна команда `plantuml` |
| `inkscape_cmd` | string | `"inkscape"` | Шлях до виконуваного файлу Inkscape для конвертації у PNG |
| `server_port` | number | `8912` | Порт для локального сервера попереднього перегляду |
| `png_dpi` | number | `800` | Роздільна здатність у DPI для експорту PNG |

## Примітки

- **Тимчасові файли**: усі тимчасові файли зберігаються у `/tmp/plantuml.nvim/`
- **Попередній перегляд у браузері**: попередній перегляд SVG запускає локальний HTTP-сервер для обслуговування згенерованих файлів
- **Вихідні файли**: команди `PlantumlCreate*` зберігають файли у `<тека-проекту>/umlout/`:
  - Плагін визначає теку проекту шляхом пошуку першої батьківської директорії, що містить `.git`
  - Якщо `.git` не знайдено, використовується поточна робоча директорія буфера
- **Розумне керування вікнами**: `PlantumlPreviewUTXT` інтелектуально керує вікном попереднього перегляду:
  - Створює нове розділене вікно, якщо вікно попереднього перегляду ще не існує
  - Оновлює існуючий буфер, якщо вікно попереднього перегляду вже відкрито
- **Команда Inkscape**: генерація PNG використовує Inkscape з наступним шаблоном команди:

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## Ліцензія

Ліцензія MIT

## Дивовижний факт

Цей проект — моя перша спроба використання `OpenCode`, і навіть більша частина цього [README.md](./README.md). Єдина частина, яку я створив повністю самостійно — це [README_FOR_AGENT.md](./README_FOR_AGENT.md).
