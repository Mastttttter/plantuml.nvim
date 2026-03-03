<h1 align="center"> ✨ plantuml.nvim pour Neovim ✨ </h1>

<p align="center">
  Un plugin Neovim pour prévisualiser et exporter des diagrammes PlantUML avec aperçu dans le navigateur, aperçu ASCII en temps réel et export PNG haute résolution.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Introduction

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Fonctionnalité 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Fonctionnalité 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Ce plugin offre une intégration fluide de PlantUML pour Neovim avec les fonctionnalités suivantes :

- **Aperçu dans le navigateur** : Génération de fichiers SVG et prévisualisation dans votre navigateur par défaut via un serveur local
- **Aperçu ASCII en temps réel** : Prévisualisation des diagrammes PlantUML sous forme d'art ASCII dans une fenêtre Neovim divisée grâce à la cible UTXT
- **Export PNG haute résolution** : Export de diagrammes en fichiers PNG haute résolution avec Inkscape pour des images nettes et prêtes pour la publication
- **Multiples formats d'export** : Prise en charge de la génération de fichiers SVG, PNG et UTXT (art ASCII)
- **Gestion intelligente des fenêtres** : Création et mise à jour intelligentes des fenêtres d'aperçu

## Installation et utilisation

### Prérequis

- **Neovim** >= 0.8.0
- **Java** (requis si vous utilisez plantuml.jar)
- **PlantUML** - au choix :
  - la commande `plantuml` disponible dans le PATH, ou
  - le fichier `plantuml.jar` (configurez le chemin dans le setup)
- **Inkscape** (optionnel, pour l'export PNG haute résolution)

### Configuration du type de fichier

Neovim ne reconnaît pas les extensions `.puml` et `.uml` par défaut. L'exemple lazy.nvim ci-dessous inclut la détection du type de fichier via la fonction `init`. Alternativement, vous pouvez ajouter ceci à votre `init.lua` (avant la configuration de lazy.nvim) :

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Installation

#### Avec [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- Chargement à la demande lors de l'ouverture de fichiers .puml ou .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Chemin vers plantuml.jar (optionnel si plantuml est dans le PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Prévisualiser PlantUML dans le navigateur" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Prévisualiser PlantUML en ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Créer un fichier SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Créer un fichier PNG (haute résolution)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Créer un fichier UTXT" },
  },
}
```

### Utilisation

1. Ouvrez un fichier PlantUML (extension `.puml` ou `.uml`) dans Neovim
2. Utilisez les commandes ou les raccourcis ci-dessous pour prévisualiser ou exporter votre diagramme

### Commandes et raccourcis

| Commande | Raccourci | Description |
|----------|-----------|-------------|
| `:PlantumlPreview` | `<leader>vup` | Génère un SVG et l'ouvre dans le navigateur par défaut |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Génère un UTXT et l'affiche dans une fenêtre divisée |
| `:PlantumlCreateSVG` | `<leader>vus` | Crée un fichier SVG dans le répertoire `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Crée un fichier PNG haute résolution (nécessite Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Crée un fichier UTXT (art ASCII) |

## Configuration

```lua
require('plantuml').setup({
  -- Chemin vers la commande java (par défaut : "java")
  java_cmd = "java",
  
  -- Chemin vers le fichier plantuml.jar (optionnel, utilise plantuml système si non défini)
  plantuml_jar = nil,
  
  -- Chemin vers la commande inkscape (par défaut : "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Port du serveur pour l'aperçu dans le navigateur (par défaut : 8080)
  server_port = 8080,
  
  -- DPI pour l'export PNG via Inkscape (par défaut : 300)
  png_dpi = 300,
})
```

### Options de configuration

| Option | Type | Par défaut | Description |
|--------|------|------------|-------------|
| `java_cmd` | string | `"java"` | Chemin vers l'exécutable Java (utilisé avec `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Chemin vers le fichier `plantuml.jar`. Si `nil`, utilise la commande système `plantuml` |
| `inkscape_cmd` | string | `"inkscape"` | Chemin vers l'exécutable Inkscape pour la conversion PNG |
| `server_port` | number | `8080` | Port pour le serveur de prévisualisation local |
| `png_dpi` | number | `300` | Résolution DPI pour l'export PNG |

## Remarques

- **Fichiers temporaires** : Tous les fichiers temporaires sont stockés dans `/tmp/plantuml.nvim/`
- **Aperçu dans le navigateur** : L'aperçu SVG exécute un serveur HTTP local pour servir les fichiers générés
- **Fichiers de sortie** : Les commandes `PlantumlCreate*` enregistrent les fichiers dans `<dossier-du-projet>/umlout/` :
  - Le plugin détecte le dossier du projet en recherchant le premier répertoire parent contenant `.git`
  - Si aucun `.git` n'est trouvé, le répertoire de travail courant du tampon est utilisé
- **Gestion intelligente des fenêtres** : `PlantumlPreviewUTXT` gère intelligemment la fenêtre d'aperçu :
  - Crée une nouvelle fenêtre divisée si aucune fenêtre d'aperçu n'existe
  - Met à jour le tampon existant si une fenêtre d'aperçu est déjà ouverte
- **Commande Inkscape** : La génération PNG utilise Inkscape avec le modèle de commande suivant :

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Licence

Licence MIT

## Un fait incroyable

Ce projet est ma première expérience avec `OpenCode`, et même la plupart de ce [README.md](./README.md). La seule partie entièrement réalisée par moi-même est [README_FOR_AGENT.md](./README_FOR_AGENT.md).
