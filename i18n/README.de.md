<h1 align="center"> ✨ plantuml.nvim für Neovim ✨ </h1>

<p align="center">
  Ein Neovim-Plugin zum Vorschauen und Exportieren von PlantUML-Diagrammen mit Browser-Vorschau, Echtzeit-ASCII-Vorschau und hochauflösendem PNG-Export.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./i18n/README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./i18n/README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./i18n/README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./i18n/README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./i18n/README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./i18n/README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./i18n/README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./i18n/README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./i18n/README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./i18n/README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./i18n/README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./i18n/README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./i18n/README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./i18n/README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./i18n/README.vi.md)

## Einführung

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Funktion 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Funktion 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Dieses Plugin bietet eine nahtlose PlantUML-Integration für Neovim mit folgenden Funktionen:

- **Browser-Vorschau**: Generierung von SVG-Dateien und Vorschau im Standardbrowser über einen lokalen Server
- **Echtzeit-ASCII-Vorschau**: Vorschau von PlantUML-Diagrammen als ASCII-Art in einem geteilten Neovim-Fenster mittels UTXT-Zielformat
- **Hochauflösender PNG-Export**: Export von Diagrammen in hochauflösende PNG-Dateien mit Inkscape für gestochen scharfe, publikationsreife Bilder
- **Mehrere Exportformate**: Unterstützung für die Generierung von SVG-, PNG- und UTXT-Dateien (ASCII-Art)
- **Intelligente Fensterverwaltung**: Intelligente Erstellung und Aktualisierung von Vorschaufenstern

## Installation & Verwendung

### Voraussetzungen

- **Neovim** >= 0.8.0
- **Java** (erforderlich bei Verwendung von plantuml.jar)
- **PlantUML** - entweder:
  - `plantuml`-Befehl im PATH verfügbar, oder
  - `plantuml.jar`-Datei (Pfad in der Konfiguration angeben)
- **Inkscape** (optional, für hochauflösenden PNG-Export)

### Dateityp-Konfiguration

Neovim erkennt die Dateierweiterungen `.puml` und `.uml` standardmäßig nicht. Das folgende lazy.nvim-Beispiel enthält die Dateityp-Erkennung über die `init`-Funktion. Alternativ können Sie dies zu Ihrer `init.lua` hinzufügen (vor der lazy.nvim-Konfiguration):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Installation

#### Mit [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Lazy Loading beim Öffnen von .puml- oder .uml-Dateien
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Pfad zu plantuml.jar (optional, wenn plantuml im PATH ist)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "PlantUML im Browser anzeigen" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "PlantUML als ASCII anzeigen" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "SVG-Datei erstellen" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "PNG-Datei erstellen (hochauflösend)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "UTXT-Datei erstellen" },
  },
}
```

### Verwendung

1. Öffnen Sie eine PlantUML-Datei (`.puml` oder `.uml` Erweiterung) in Neovim
2. Verwenden Sie die Befehle oder Tastenkombinationen unten, um Ihr Diagramm voranzuschauen oder zu exportieren

### Befehle & Tastenkombinationen

| Befehl | Tastenkombination | Beschreibung |
|--------|-------------------|--------------|
| `:PlantumlPreview` | `<leader>vup` | Generiert SVG und zeigt es im Standardbrowser an |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Generiert UTXT und zeigt es in einem geteilten Fenster an |
| `:PlantumlCreateSVG` | `<leader>vus` | Erstellt SVG-Datei im `umlout/`-Verzeichnis |
| `:PlantumlCreatePNG` | `<leader>vug` | Erstellt hochauflösende PNG-Datei (erfordert Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Erstellt UTXT-Datei (ASCII-Art) |

## Konfiguration

```lua
require('plantuml').setup({
  -- Pfad zum Java-Befehl (Standard: "java")
  java_cmd = "java",
  
  -- Pfad zur plantuml.jar-Datei (optional, verwendet systemweites plantuml wenn nicht gesetzt)
  plantuml_jar = nil,
  
  -- Pfad zum Inkscape-Befehl (Standard: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Server-Port für Browser-Vorschau (Standard: 8080)
  server_port = 8080,
  
  -- DPI für PNG-Export über Inkscape (Standard: 300)
  png_dpi = 300,
})
```

### Konfigurationsoptionen

| Option | Typ | Standard | Beschreibung |
|--------|-----|----------|--------------|
| `java_cmd` | string | `"java"` | Pfad zur Java-Executable (verwendet mit `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Pfad zur `plantuml.jar`-Datei. Wenn `nil`, wird der systemweite `plantuml`-Befehl verwendet |
| `inkscape_cmd` | string | `"inkscape"` | Pfad zur Inkscape-Executable für PNG-Konvertierung |
| `server_port` | number | `8080` | Port für den lokalen Vorschau-Server |
| `png_dpi` | number | `300` | DPI-Auflösung für PNG-Export |

## Hinweise

- **Temporäre Dateien**: Alle temporären Dateien werden in `/tmp/plantuml.nvim/` gespeichert
- **Browser-Vorschau**: Die SVG-Vorschau startet einen lokalen HTTP-Server, um die generierten Dateien bereitzustellen
- **Ausgabedateien**: Die `PlantumlCreate*`-Befehle speichern Dateien in `<Projektordner>/umlout/`:
  - Das Plugin erkennt den Projektordner durch Suche nach dem ersten übergeordneten Verzeichnis, das `.git` enthält
  - Wenn kein `.git` gefunden wird, wird das aktuelle Arbeitsverzeichnis des Buffers verwendet
- **Intelligente Fensterverwaltung**: `PlantumlPreviewUTXT` verwaltet das Vorschaufenster intelligent:
  - Erstellt ein neues geteiltes Fenster, wenn noch kein Vorschaufenster existiert
  - Aktualisiert den bestehenden Buffer, wenn bereits ein Vorschaufenster geöffnet ist
- **Inkscape-Befehl**: Die PNG-Generierung verwendet Inkscape mit folgendem Befehlsmuster:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Lizenz

MIT-Lizenz

## Ein erstaunliches Faktum

Dieses Projekt ist mein erster Versuch mit `OpenCode`, und sogar der größte Teil dieser [README.md](./README.md). Der einzige Teil, den ich vollständig selbst erstellt habe, ist [README_FOR_AGENT.md](./README_FOR_AGENT.md).