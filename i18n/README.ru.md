<h1 align="center"> ✨ plantuml.nvim для Neovim ✨ </h1>

<p align="center">
  Плагин для Neovim для предпросмотра и экспорта диаграмм PlantUML с просмотром в браузере, предварительным просмотром в реальном времени в формате ASCII и экспортом в PNG высокого разрешения.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Введение

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Функция 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Функция 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Этот плагин обеспечивает бесшовную интеграцию PlantUML для Neovim со следующими возможностями:

- **Просмотр в браузере**: генерация SVG-файлов и их предпросмотр в браузере по умолчанию через локальный сервер
- **Предварительный просмотр ASCII в реальном времени**: просмотр диаграмм PlantUML в формате ASCII-графики в разделённом окне Neovim с использованием формата UTXT
- **Экспорт в PNG высокого разрешения**: экспорт диаграмм в высококачественные PNG-файлы с помощью Inkscape для чётких изображений, готовых к публикации
- **Поддержка нескольких форматов экспорта**: генерация файлов в форматах SVG, PNG и UTXT (ASCII-графика)
- **Умное управление окнами**: интеллектуальное создание и обновление окон предпросмотра

## Установка и использование

### Требования

- **Neovim** >= 0.8.0
- **Java** (требуется при использовании plantuml.jar)
- **PlantUML** - одно из следующего:
  - команда `plantuml` доступна в PATH, или
  - файл `plantuml.jar` (настроить путь в конфигурации)
- **Inkscape** (опционально, для экспорта в PNG высокого разрешения)
- **Node.js**

### Настройка типа файлов

Neovim по умолчанию не распознаёт расширения файлов `.puml` и `.uml`. Приведённый ниже пример для lazy.nvim включает определение типа файлов через функцию `init`. В качестве альтернативы вы можете добавить это в ваш `init.lua` (перед настройкой lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Установка

#### С помощью [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Отложенная загрузка при открытии файлов .puml или .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Путь к plantuml.jar (опционально, если plantuml в PATH)
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Предпросмотр PlantUML в браузере" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Предпросмотр PlantUML как ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Создать файл SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Создать файл PNG (высокое разрешение)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Создать файл UTXT" },
  },
}
```

### Использование

1. Откройте файл PlantUML (с расширением `.puml` или `.uml`) в Neovim
2. Используйте команды или клавиатурные сокращения ниже для предпросмотра или экспорта вашей диаграммы

### Команды и клавиатурные сокращения

| Команда | Клавиатурное сокращение | Описание |
|---------|-------------------------|----------|
| `:PlantumlPreview` | `<leader>vup` | Генерирует SVG и открывает предпросмотр в браузере по умолчанию |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Генерирует UTXT и показывает в разделённом окне |
| `:PlantumlCreateSVG` | `<leader>vus` | Создаёт файл SVG в директории `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Создаёт файл PNG высокого разрешения (требует Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Создаёт файл UTXT (ASCII-графика) |

## Конфигурация

```lua
require('plantuml').setup({
  -- Путь к команде java (по умолчанию: "java")
  java_cmd = "java",
  
  -- Путь к файлу plantuml.jar (опционально, используется системный plantuml, если не задан)
  plantuml_jar = nil,
  
  -- Путь к команде inkscape (по умолчанию: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Порт сервера для предпросмотра в браузере (по умолчанию: 8912)
  server_port = 8912,
  
  -- DPI для экспорта PNG через Inkscape (по умолчанию: 800)
  png_dpi = 800,
})
```

### Параметры конфигурации

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `java_cmd` | string | `"java"` | Путь к исполняемому файлу Java (используется с `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Путь к файлу `plantuml.jar`. Если `nil`, используется системная команда `plantuml` |
| `inkscape_cmd` | string | `"inkscape"` | Путь к исполняемому файлу Inkscape для конвертации в PNG |
| `server_port` | number | `8912` | Порт для локального сервера предпросмотра |
| `png_dpi` | number | `800` | Разрешение в DPI для экспорта PNG |

## Примечания

- **Временные файлы**: все временные файлы хранятся в `/tmp/plantuml.nvim/`
- **Предпросмотр в браузере**: предпросмотр SVG запускает локальный HTTP-сервер для обслуживания сгенерированных файлов
- **Выходные файлы**: команды `PlantumlCreate*` сохраняют файлы в `<папка-проекта>/umlout/`:
  - Плагин определяет папку проекта путём поиска первой родительской директории, содержащей `.git`
  - Если `.git` не найден, используется текущая рабочая директория буфера
- **Умное управление окнами**: `PlantumlPreviewUTXT` интеллектуально управляет окном предпросмотра:
  - Создаёт новое разделённое окно, если окно предпросмотра ещё не существует
  - Обновляет существующий буфер, если окно предпросмотра уже открыто
- **Команда Inkscape**: генерация PNG использует Inkscape со следующим шаблоном команды:

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## Лицензия

Лицензия MIT

## Удивительный факт

Этот проект — моя первая попытка использования `OpenCode`, и даже большая часть этого [README.md](./README.md). Единственная часть, которую я создал полностью самостоятельно — это [README_FOR_AGENT.md](./README_FOR_AGENT.md).
