<h1 align="center"> ✨ plantuml.nvim for Neovim ✨ </h1>

<p align="center">
  Neovim용 PlantUML 플러그인 - 브라우저 미리보기, 실시간 ASCII 미리보기, 고해상도 PNG 내보내기 지원
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## 소개

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

이 플러그인은 Neovim에서 PlantUML을 완벽하게 통합하여 다음 기능을 제공합니다:

- **브라우저 미리보기**: SVG 파일을 생성하고 로컬 서버를 통해 기본 브라우저에서 미리보기
- **실시간 ASCII 미리보기**: UTXT 타겟을 사용하여 Neovim 분할 창에서 PlantUML 다이어그램을 ASCII 아트로 미리보기
- **고해상도 PNG 내보내기**: Inkscape를 사용하여 선명하고 출판 품질의 고해상도 PNG 파일로 내보내기
- **다양한 내보내기 형식**: SVG, PNG, UTXT(ASCII 아트) 파일 생성 지원
- **스마트 창 관리**: 미리보기 창 생성 및 업데이트를 자동으로 관리

## 설치 및 사용법

### 필수 요구사항

- **Neovim** >= 0.8.0
- **Java** (plantuml.jar 사용 시 필요)
- **PlantUML** - 다음 중 하나:
  - PATH에서 `plantuml` 명령어 사용 가능, 또는
  - `plantuml.jar` 파일 (설정에서 경로 지정)
- **Inkscape** (선택사항, 고해상도 PNG 내보내기용)
- **Node.js**

### 파일 타입 설정

Neovim은 기본적으로 `.puml`과 `.uml` 파일 확장자를 인식하지 않습니다. 아래 lazy.nvim 예제에서는 `init` 함수를 통해 파일 타입 감지를 설정합니다. 또는 `init.lua`에 다음을 추가할 수 있습니다 (lazy.nvim 설정 이전):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### 설치

#### [lazy.nvim](https://github.com/folke/lazy.nvim) 사용 시

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
  ft = { "plantuml" },  -- .puml 또는 .uml 파일 열 때 지연 로드
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- plantuml.jar 경로 (plantuml이 PATH에 있는 경우 선택사항)
      inkscape_cmd = "inkscape",
      server_port = 8912,
      png_dpi = 800,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "브라우저에서 PlantUML 미리보기" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "ASCII로 PlantUML 미리보기" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "SVG 파일 생성" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "고해상도 PNG 파일 생성" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "UTXT 파일 생성" },
  },
}
```

### 사용법

1. Neovim에서 PlantUML 파일(`.puml` 또는 `.uml` 확장자) 열기
2. 아래의 명령어 또는 키바인딩을 사용하여 다이어그램 미리보기 또는 내보내기

### 명령어 및 키바인딩

| 명령어 | 키바인딩 | 설명 |
|--------|----------|------|
| `:PlantumlPreview` | `<leader>vup` | SVG 생성 후 기본 브라우저에서 미리보기 |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | UTXT 생성 후 분할 창에서 미리보기 |
| `:PlantumlCreateSVG` | `<leader>vus` | `umlout/` 디렉터리에 SVG 파일 생성 |
| `:PlantumlCreatePNG` | `<leader>vug` | 고해상도 PNG 파일 생성 (Inkscape 필요) |
| `:PlantumlCreateUTXT` | `<leader>vut` | UTXT(ASCII 아트) 파일 생성 |

## 설정

```lua
require('plantuml').setup({
  -- Java 명령어 경로 (기본값: "java")
  java_cmd = "java",
  
  -- plantuml.jar 파일 경로 (선택사항, 설정하지 않으면 시스템 plantuml 사용)
  plantuml_jar = nil,
  
  -- Inkscape 명령어 경로 (기본값: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- 브라우저 미리보기용 서버 포트 (기본값: 8912)
  server_port = 8912,
  
  -- Inkscape를 통한 PNG 내보내기 DPI (기본값: 800)
  png_dpi = 800,
})
```

### 설정 옵션

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `java_cmd` | string | `"java"` | Java 실행 파일 경로 (`plantuml_jar` 사용 시 필요) |
| `plantuml_jar` | string \| nil | `nil` | `plantuml.jar` 파일 경로. `nil`인 경우 시스템 `plantuml` 명령어 사용 |
| `inkscape_cmd` | string | `"inkscape"` | PNG 변환용 Inkscape 실행 파일 경로 |
| `server_port` | number | `8912` | 로컬 미리보기 서버 포트 번호 |
| `png_dpi` | number | `800` | PNG 내보내기 DPI 해상도 |

## 참고사항

- **임시 파일**: 모든 임시 파일은 `/tmp/plantuml.nvim/`에 저장됩니다
- **브라우저 미리보기**: SVG 미리보기는 생성된 파일을 제공하기 위해 로컬 HTTP 서버를 실행합니다
- **출력 파일**: `PlantumlCreate*` 명령어는 `<프로젝트 폴더>/umlout/`에 파일을 저장합니다:
  - 플러그인은 `.git`이 포함된 첫 번째 상위 디렉터리를 찾아 프로젝트 폴더를 감지합니다
  - `.git`을 찾지 못하면 버퍼의 현재 작업 디렉터리를 사용합니다
- **스마트 창 관리**: `PlantumlPreviewUTXT`는 미리보기 창을 자동으로 관리합니다:
  - 미리보기 창이 없으면 새 분할 창을 생성
  - 미리보기 창이 이미 열려있으면 기존 버퍼를 업데이트
- **Inkscape 명령어**: PNG 생성은 다음 명령어 패턴으로 Inkscape를 사용합니다:

  ```bash
  inkscape --export-dpi=800 --export-filename=output.png input.svg
  ```

## 라이선스

MIT License

## 흥미로운 사실

이 프로젝트는 제가 `OpenCode`를 사용한 첫 번째 시도입니다. 심지어 이 [README.md](./README.md)의 대부분도 마찬가지입니다. 제가 직접 완성한 유일한 부분은 [README_FOR_AGENT.md](./README_FOR_AGENT.md)입니다.
