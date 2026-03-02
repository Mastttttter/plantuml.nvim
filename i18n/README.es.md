<h1 align="center"> ✨ plantuml.nvim para Neovim ✨ </h1>

<p align="center">
  Un plugin de Neovim para previsualizar y exportar diagramas PlantUML con vista previa en navegador, previsualización ASCII en tiempo real y exportación PNG de alta resolución.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./i18n/README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./i18n/README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./i18n/README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./i18n/README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./i18n/README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./i18n/README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./i18n/README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./i18n/README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./i18n/README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./i18n/README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./i18n/README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./i18n/README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./i18n/README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./i18n/README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./i18n/README.vi.md)

## Introducción

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Característica 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Característica 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Este plugin ofrece una integración perfecta de PlantUML para Neovim con las siguientes características:

- **Previsualización en Navegador**: Genera archivos SVG y los previsualiza en tu navegador predeterminado mediante un servidor local
- **Previsualización ASCII en Tiempo Real**: Previsualiza diagramas PlantUML como arte ASCII en una ventana dividida de Neovim usando el objetivo UTXT
- **Exportación PNG de Alta Resolución**: Exporta diagramas a archivos PNG de alta resolución usando Inkscape para obtener imágenes nítidas y listas para publicar
- **Múltiples Formatos de Exportación**: Soporte para generación de archivos SVG, PNG y UTXT (arte ASCII)
- **Gestión Inteligente de Ventanas**: Creación y actualización inteligente de ventanas de previsualización

## Instalación y Uso

### Requisitos Previos

- **Neovim** >= 0.8.0
- **Java** (requerido si usas plantuml.jar)
- **PlantUML** - una de las siguientes opciones:
  - Comando `plantuml` disponible en el PATH, o
  - Archivo `plantuml.jar` (configura la ruta en la instalación)
- **Inkscape** (opcional, para exportación PNG de alta resolución)

### Configuración del Tipo de Archivo

Neovim no reconoce las extensiones `.puml` y `.uml` por defecto. El ejemplo con lazy.nvim a continuación incluye la detección del tipo de archivo mediante la función `init`. Alternativamente, puedes añadir esto a tu `init.lua` (antes de la configuración de lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Instalación

#### Usando [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Carga diferida al abrir archivos .puml o .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Ruta a plantuml.jar (opcional si plantuml está en PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Previsualizar PlantUML en navegador" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Previsualizar PlantUML como ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Crear archivo SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Crear archivo PNG (alta resolución)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Crear archivo UTXT" },
  },
}
```

### Uso

1. Abre un archivo PlantUML (con extensión `.puml` o `.uml`) en Neovim
2. Usa los comandos o atajos de teclado a continuación para previsualizar o exportar tu diagrama

### Comandos y Atajos de Teclado

| Comando | Atajo | Descripción |
|---------|-------|-------------|
| `:PlantumlPreview` | `<leader>vup` | Genera SVG y lo previsualiza en el navegador predeterminado |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Genera UTXT y lo previsualiza en una ventana dividida |
| `:PlantumlCreateSVG` | `<leader>vus` | Crea archivo SVG en el directorio `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Crea archivo PNG de alta resolución (requiere Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Crea archivo UTXT (arte ASCII) |

## Configuración

```lua
require('plantuml').setup({
  -- Ruta al comando java (por defecto: "java")
  java_cmd = "java",
  
  -- Ruta al archivo plantuml.jar (opcional, usa plantuml del sistema si no está configurado)
  plantuml_jar = nil,
  
  -- Ruta al comando inkscape (por defecto: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Puerto del servidor para previsualización en navegador (por defecto: 8080)
  server_port = 8080,
  
  -- DPI para exportación PNG mediante Inkscape (por defecto: 300)
  png_dpi = 300,
})
```

### Opciones de Configuración

| Opción | Tipo | Por Defecto | Descripción |
|--------|------|-------------|-------------|
| `java_cmd` | string | `"java"` | Ruta al ejecutable de Java (usado con `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Ruta al archivo `plantuml.jar`. Si es `nil`, usa el comando `plantuml` del sistema |
| `inkscape_cmd` | string | `"inkscape"` | Ruta al ejecutable de Inkscape para conversión PNG |
| `server_port` | number | `8080` | Puerto para el servidor local de previsualización |
| `png_dpi` | number | `300` | Resolución DPI para exportación PNG |

## Notas

- **Archivos Temporales**: Todos los archivos temporales se almacenan en `/tmp/plantuml.nvim/`
- **Previsualización en Navegador**: La previsualización SVG ejecuta un servidor HTTP local para servir los archivos generados
- **Archivos de Salida**: Los comandos `PlantumlCreate*` guardan los archivos en `<carpeta-del-proyecto>/umlout/`:
  - El plugin detecta la carpeta del proyecto buscando el primer directorio padre que contenga `.git`
  - Si no se encuentra `.git`, se usa el directorio de trabajo actual del buffer
- **Gestión Inteligente de Ventanas**: `PlantumlPreviewUTXT` gestiona inteligentemente la ventana de previsualización:
  - Crea una nueva ventana dividida si no existe una ventana de previsualización
  - Actualiza el buffer existente si ya hay una ventana de previsualización abierta
- **Comando Inkscape**: La generación de PNG usa Inkscape con el siguiente patrón de comando:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Licencia

Licencia MIT

## Un dato increíble

Este proyecto es mi primer intento usando `OpenCode`, incluso la mayor parte de este [README.md](../README.md). La única parte terminada puramente por mí es [README_FOR_AGENT.md](../README_FOR_AGENT.md).