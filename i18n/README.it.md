<h1 align="center"> ✨ plantuml.nvim per Neovim ✨ </h1>

<p align="center">
  Un plugin per Neovim per l'anteprima e l'esportazione di diagrammi PlantUML con anteprima nel browser, anteprima ASCII in tempo reale ed esportazione PNG ad alta risoluzione.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Introduzione

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Funzionalità 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Funzionalità 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Questo plugin offre un'integrazione impeccabile di PlantUML per Neovim con le seguenti funzionalità:

- **Anteprima nel browser**: Genera file SVG e visualizzali nel browser predefinito tramite un server locale
- **Anteprima ASCII in tempo reale**: Visualizza i diagrammi PlantUML come arte ASCII in una finestra divisa di Neovim utilizzando il target UTXT
- **Esportazione PNG ad alta risoluzione**: Esporta i diagrammi in file PNG ad alta risoluzione utilizzando Inkscape per immagini nitide e pronte per la pubblicazione
- **Diversi formati di esportazione**: Supporto per la generazione di file SVG, PNG e UTXT (arte ASCII)
- **Gestione intelligente delle finestre**: Creazione e aggiornamento intelligenti delle finestre di anteprima

## Installazione e utilizzo

### Prerequisiti

- **Neovim** >= 0.8.0
- **Java** (necessario se si utilizza plantuml.jar)
- **PlantUML** - una delle seguenti opzioni:
  - comando `plantuml` disponibile nel PATH, oppure
  - file `plantuml.jar` (configura il percorso nel setup)
- **Inkscape** (opzionale, per l'esportazione PNG ad alta risoluzione)

### Configurazione del tipo di file

Neovim non riconosce le estensioni `.puml` e `.uml` per impostazione predefinita. L'esempio con lazy.nvim riportato di seguito include il rilevamento del tipo di file tramite la funzione `init`. In alternativa, puoi aggiungere questo al tuo `init.lua` (prima della configurazione di lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Installazione

#### Con [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Caricamento differito all'apertura di file .puml o .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Percorso di plantuml.jar (opzionale se plantuml è nel PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Anteprima PlantUML nel browser" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Anteprima PlantUML come ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Crea file SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Crea file PNG (alta risoluzione)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Crea file UTXT" },
  },
}
```

### Utilizzo

1. Apri un file PlantUML (estensione `.puml` o `.uml`) in Neovim
2. Usa i comandi o le scorciatoie da tastiera riportati di seguito per visualizzare o esportare il tuo diagramma

### Comandi e scorciatoie da tastiera

| Comando | Scorciatoia | Descrizione |
|---------|-------------|-------------|
| `:PlantumlPreview` | `<leader>vup` | Genera SVG e apre l'anteprima nel browser predefinito |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Genera UTXT e visualizza l'anteprima in una finestra divisa |
| `:PlantumlCreateSVG` | `<leader>vus` | Crea un file SVG nella cartella `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Crea un file PNG ad alta risoluzione (richiede Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Crea un file UTXT (arte ASCII) |

## Configurazione

```lua
require('plantuml').setup({
  -- Percorso del comando java (predefinito: "java")
  java_cmd = "java",
  
  -- Percorso del file plantuml.jar (opzionale, usa plantuml di sistema se non impostato)
  plantuml_jar = nil,
  
  -- Percorso del comando inkscape (predefinito: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Porta del server per l'anteprima nel browser (predefinito: 8080)
  server_port = 8080,
  
  -- DPI per l'esportazione PNG tramite Inkscape (predefinito: 300)
  png_dpi = 300,
})
```

### Opzioni di configurazione

| Opzione | Tipo | Predefinito | Descrizione |
|---------|------|-------------|-------------|
| `java_cmd` | string | `"java"` | Percorso dell'eseguibile Java (usato con `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Percorso del file `plantuml.jar`. Se `nil`, usa il comando `plantuml` di sistema |
| `inkscape_cmd` | string | `"inkscape"` | Percorso dell'eseguibile Inkscape per la conversione PNG |
| `server_port` | number | `8080` | Porta per il server di anteprima locale |
| `png_dpi` | number | `300` | Risoluzione DPI per l'esportazione PNG |

## Note

- **File temporanei**: Tutti i file temporanei sono salvati in `/tmp/plantuml.nvim/`
- **Anteprima nel browser**: L'anteprima SVG esegue un server HTTP locale per servire i file generati
- **File di output**: I comandi `PlantumlCreate*` salvano i file in `<cartella-progetto>/umlout/`:
  - Il plugin rileva la cartella del progetto cercando la prima directory genitore che contiene `.git`
  - Se non viene trovato `.git`, viene utilizzata la directory di lavoro corrente del buffer
- **Gestione intelligente delle finestre**: `PlantumlPreviewUTXT` gestisce intelligentemente la finestra di anteprima:
  - Crea una nuova finestra divisa se non esiste una finestra di anteprima
  - Aggiorna il buffer esistente se una finestra di anteprima è già aperta
- **Comando Inkscape**: La generazione PNG utilizza Inkscape con il seguente modello di comando:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Licenza

Licenza MIT

## Un fatto incredibile

Questo progetto è la mia prima esperienza con `OpenCode`, inclusa la maggior parte di questo [README.md](./README.md). L'unica parte interamente realizzata da me è [README_FOR_AGENT.md](./README_FOR_AGENT.md).
