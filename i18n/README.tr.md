<h1 align="center"> ✨ Neovim için plantuml.nvim ✨ </h1>

<p align="center">
  Neovim eklentisi: PlantUML diyagramlarını tarayıcı önizlemesi, gerçek zamanlı ASCII önizlemesi ve yüksek çözünürlüklü PNG dışa aktarımı ile görüntüleme ve dışa aktarma.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./i18n/README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./i18n/README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./i18n/README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./i18n/README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./i18n/README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./i18n/README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./i18n/README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./i18n/README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./i18n/README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./i18n/README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./i18n/README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./i18n/README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./i18n/README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./i18n/README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./i18n/README.vi.md)

## Giriş

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="Özellik 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="Özellik 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

Bu eklenti, Neovim için kusursuz bir PlantUML entegrasyonu sağlar ve şu özellikleri sunar:

- **Tarayıcı Önizlemesi**: Yerel bir sunucu aracılığıyla SVG dosyaları oluşturma ve varsayılan tarayıcınızda görüntüleme
- **Gerçek Zamanlı ASCII Önizleme**: UTXT hedef biçimini kullanarak PlantUML diyagramlarını bölünmüş bir Neovim penceresinde ASCII sanatı olarak önizleme
- **Yüksek Çözünürlüklü PNG Dışa Aktarma**: Inkscape kullanarak diyagramları yüksek çözünürlüklü PNG dosyalarına aktarma; keskin, yayın kalitesinde görseller
- **Çoklu Dışa Aktarma Biçimleri**: SVG, PNG ve UTXT (ASCII sanatı) dosya oluşturma desteği
- **Akıllı Pencere Yönetimi**: Önizleme pencerelerinin akıllıca oluşturulması ve güncellenmesi

## Kurulum ve Kullanım

### Gereksinimler

- **Neovim** >= 0.8.0
- **Java** (plantuml.jar kullanılıyorsa gereklidir)
- **PlantUML** - aşağıdakilerden biri:
  - `plantuml` komutu PATH'te mevcut olmalı, veya
  - `plantuml.jar` dosyası (kurulumda yolunu yapılandırın)
- **Inkscape** (isteğe bağlı, yüksek çözünürlüklü PNG dışa aktarımı için)

### Dosya Türü Yapılandırması

Neovim, `.puml` ve `.uml` dosya uzantılarını varsayılan olarak tanımaz. Aşağıdaki lazy.nvim örneği, `init` işlevi aracılığıyla dosya türü algılamayı içerir. Alternatif olarak, bunu `init.lua` dosyanıza ekleyebilirsiniz (lazy.nvim kurulumundan önce):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### Kurulum

#### [lazy.nvim](https://github.com/folke/lazy.nvim) ile

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
  ft = { "plantuml" },  -- .puml veya .uml dosyaları açıldığında tembel yükleme
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- plantuml.jar yolu (plantuml PATH'teyse isteğe bağlı)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "PlantUML'ü tarayıcıda önizle" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "PlantUML'ü ASCII olarak önizle" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "SVG dosyası oluştur" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "PNG dosyası oluştur (yüksek çözünürlüklü)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "UTXT dosyası oluştur" },
  },
}
```

### Kullanım

1. Neovim'de bir PlantUML dosyası açın (`.puml` veya `.uml` uzantılı)
2. Diyagramınızı önizlemek veya dışa aktarmak için aşağıdaki komutları veya tuş bağlamalarını kullanın

### Komutlar ve Tuş Bağlamaları

| Komut | Tuş Bağlaması | Açıklama |
|-------|---------------|----------|
| `:PlantumlPreview` | `<leader>vup` | SVG oluşturur ve varsayılan tarayıcıda görüntüler |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | UTXT oluşturur ve bölünmüş bir pencerede görüntüler |
| `:PlantumlCreateSVG` | `<leader>vus` | `umlout/` dizininde SVG dosyası oluşturur |
| `:PlantumlCreatePNG` | `<leader>vug` | Yüksek çözünürlüklü PNG dosyası oluşturur (Inkscape gerektirir) |
| `:PlantumlCreateUTXT` | `<leader>vut` | UTXT (ASCII sanatı) dosyası oluşturur |

## Yapılandırma

```lua
require('plantuml').setup({
  -- Java komutunun yolu (varsayılan: "java")
  java_cmd = "java",
  
  -- plantuml.jar dosyasının yolu (isteğe bağlı, ayarlanmazsa sistem plantuml komutunu kullanır)
  plantuml_jar = nil,
  
  -- Inkscape komutunun yolu (varsayılan: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Tarayıcı önizlemesi için sunucu portu (varsayılan: 8080)
  server_port = 8080,
  
  -- Inkscape aracılığıyla PNG dışa aktarımı için DPI (varsayılan: 300)
  png_dpi = 300,
})
```

### Yapılandırma Seçenekleri

| Seçenek | Tür | Varsayılan | Açıklama |
|---------|-----|------------|----------|
| `java_cmd` | string | `"java"` | Java çalıştırılabilir dosyasının yolu (`plantuml_jar` ile kullanılır) |
| `plantuml_jar` | string \| nil | `nil` | `plantuml.jar` dosyasının yolu. `nil` ise, sistem `plantuml` komutunu kullanır |
| `inkscape_cmd` | string | `"inkscape"` | PNG dönüştürme için Inkscape çalıştırılabilir dosyasının yolu |
| `server_port` | number | `8080` | Yerel önizleme sunucusu için port |
| `png_dpi` | number | `300` | PNG dışa aktarımı için DPI çözünürlüğü |

## Notlar

- **Geçici Dosyalar**: Tüm geçici dosyalar `/tmp/plantuml.nvim/` dizinde saklanır
- **Tarayıcı Önizlemesi**: SVG önizlemesi, oluşturulan dosyaları sunmak için yerel bir HTTP sunucusu çalıştırır
- **Çıktı Dosyaları**: `PlantumlCreate*` komutları dosyaları `<proje-klasörü>/umlout/` dizinine kaydeder:
  - Eklenti, `.git` içeren ilk üst dizini bularak proje klasörünü algılar
  - `.git` bulunamazsa, arabelleğin geçerli çalışma dizini kullanılır
- **Akıllı Pencere Yönetimi**: `PlantumlPreviewUTXT`, önizleme penceresini akıllıca yönetir:
  - Henüz önizleme penceresi yoksa yeni bir bölünmüş pencere oluşturur
  - Önizleme penceresi zaten açıksa mevcut arabelleği günceller
- **Inkscape Komutu**: PNG oluşturma, Inkscape'i şu komut kalıbıyla kullanır:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## Lisans

MIT Lisansı

## Şaşırtıcı Bir Gerçek

Bu proje, `OpenCode` kullanarak yaptığım ilk denememdir, hatta bu [README.md](./README.md)'nin büyük bir kısmı bile. Tamamen kendimin yazdığı tek bölüm [README_FOR_AGENT.md](./README_FOR_AGENT.md) dosyasıdır.