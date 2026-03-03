<h1 align="center"> ✨ plantuml.nvim para Neovim ✨ </h1>

<p align="center">
  Um plugin para Neovim que permite visualizar e exportar diagramas PlantUML com pré-visualização no navegador, visualização ASCII em tempo real e exportação de PNG em alta resolução.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## Introdução

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Funcionalidade 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Funcionalidade 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Este plugin oferece uma integração perfeita do PlantUML com o Neovim, contando com as seguintes funcionalidades:

- **Pré-visualização no Navegador**: Gera arquivos SVG e os exibe no navegador padrão através de um servidor local
- **Pré-visualização ASCII em Tempo Real**: Visualiza diagramas PlantUML como arte ASCII em uma janela dividida do Neovim usando o destino UTXT
- **Exportação de PNG em Alta Resolução**: Exporta diagramas para arquivos PNG de alta qualidade usando o Inkscape, resultando em imagens nítidas e prontas para publicação
- **Múltiplos Formatos de Exportação**: Suporte para geração de arquivos nos formatos SVG, PNG e UTXT (arte ASCII)
- **Gerenciamento Inteligente de Janelas**: Criação e atualização inteligente da janela de pré-visualização

## Instalação e Uso

### Pré-requisitos

- **Neovim** >= 0.8.0
- **Java** (obrigatório se estiver usando plantuml.jar)
- **PlantUML** - uma das opções:
  - Comando `plantuml` disponível no PATH, ou
  - Arquivo `plantuml.jar` (configure o caminho na inicialização)
- **Inkscape** (opcional, para exportação de PNG em alta resolução)
- **Node.js**

### Configuração de Tipo de Arquivo

O Neovim não reconhece as extensões `.puml` e `.uml` por padrão. O exemplo com lazy.nvim abaixo inclui a detecção de tipo de arquivo através da função `init`. Alternativamente, você pode adicionar isso ao seu `init.lua` (antes da configuração do lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Instalação

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
  ft = { "plantuml" },  -- Carregamento preguiçoso ao abrir arquivos .puml ou .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- Caminho para plantuml.jar (opcional se plantuml estiver no PATH)
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "Visualizar PlantUML no navegador" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "Visualizar PlantUML como ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "Criar arquivo SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "Criar arquivo PNG (alta resolução)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "Criar arquivo UTXT" },
  },
}
```

### Uso

1. Abra um arquivo PlantUML (com extensão `.puml` ou `.uml`) no Neovim
2. Use os comandos ou atalhos abaixo para visualizar ou exportar seu diagrama

### Comandos e Atalhos

| Comando | Atalho | Descrição |
|---------|--------|-----------|
| `:PlantumlPreview` | `<leader>vup` | Gera SVG e visualiza no navegador padrão |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | Gera UTXT e visualiza em uma janela dividida |
| `:PlantumlCreateSVG` | `<leader>vus` | Cria arquivo SVG no diretório `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | Cria arquivo PNG em alta resolução (requer Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | Cria arquivo UTXT (arte ASCII) |

## Configuração

```lua
require('plantuml').setup({
  -- Caminho para o comando java (padrão: "java")
  java_cmd = "java",
  
  -- Caminho para o arquivo plantuml.jar (opcional, usa plantuml do sistema se não definido)
  plantuml_jar = nil,
  
  -- Caminho para o comando inkscape (padrão: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Porta do servidor para pré-visualização no navegador (padrão: 8912)
  server_port = 8912,
  
  -- DPI para exportação de PNG via Inkscape (padrão: 800)
  png_dpi = 800,
})
```

### Opções de Configuração

| Opção | Tipo | Padrão | Descrição |
|-------|------|--------|-----------|
| `java_cmd` | string | `"java"` | Caminho para o executável Java (usado com `plantuml_jar`) |
| `plantuml_jar` | string \| nil | `nil` | Caminho para o arquivo `plantuml.jar`. Se `nil`, usa o comando `plantuml` do sistema |
| `inkscape_cmd` | string | `"inkscape"` | Caminho para o executável Inkscape para conversão de PNG |
| `server_port` | number | `8912` | Porta para o servidor local de pré-visualização |
| `png_dpi` | number | `800` | Resolução DPI para exportação de PNG |

## Observações

- **Arquivos Temporários**: Todos os arquivos temporários são armazenados em `/tmp/plantuml.nvim/`
- **Pré-visualização no Navegador**: A visualização SVG executa um servidor HTTP local para servir os arquivos gerados
- **Arquivos de Saída**: Os comandos `PlantumlCreate*` salvam os arquivos em `<pasta-do-projeto>/umlout/`:
  - O plugin detecta a pasta do projeto procurando o primeiro diretório pai que contenha `.git`
  - Se nenhum `.git` for encontrado, o diretório de trabalho atual do buffer é utilizado
- **Gerenciamento Inteligente de Janelas**: `PlantumlPreviewUTXT` gerencia a janela de pré-visualização de forma inteligente:
  - Cria uma nova janela dividida se não existir uma janela de pré-visualização
  - Atualiza o buffer existente se uma janela de pré-visualização já estiver aberta
- **Comando Inkscape**: A geração de PNG usa o Inkscape com o seguinte padrão de comando:

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## Licença

Licença MIT

## Um fato incrível

Este projeto é minha primeira experiência usando `OpenCode`, inclusive a maior parte deste [README.md](../README.md). A única parte feita inteiramente por mim é o [README_FOR_AGENT.md](../README_FOR_AGENT.md).
