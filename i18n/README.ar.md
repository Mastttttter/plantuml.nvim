<h1 align="center"> ✨ plantuml.nvim لـ Neovim ✨ </h1>

<p align="center">
  إضافة Neovim لمعاينة وتصدير مخططات PlantUML مع معاينة في المتصفح، ومعاينة ASCII في الوقت الفعلي، وتصدير PNG بدقة عالية.
</p>

[![繁體中文](https://img.shields.io/badge/docs-繁體中文-yellow)](./README.zh-TW.md) [![简体中文](https://img.shields.io/badge/docs-简体中文-yellow)](./README.zh-CN.md) [![日本語](https://img.shields.io/badge/docs-日本語-b7003a)](./README.ja.md) [![한국어 문서](https://img.shields.io/badge/docs-한국어-green)](./README.ko.md) [![Documentación en Español](https://img.shields.io/badge/docs-Español-orange)](./README.es.md) [![Documentation en Français](https://img.shields.io/badge/docs-Français-blue)](./README.fr.md) [![Documentação em Português (Brasil)](<https://img.shields.io/badge/docs-Português%20(Brasil)-purple>)](./README.pt-BR.md) [![Documentazione in italiano](https://img.shields.io/badge/docs-Italian-red)](./README.it.md) [![Dokumentasi Bahasa Indonesia](https://img.shields.io/badge/docs-Bahasa%20Indonesia-pink)](./README.id-ID.md) [![Dokumentation auf Deutsch](https://img.shields.io/badge/docs-Deutsch-darkgreen)](./README.de.md) [![Документация на русском языке](https://img.shields.io/badge/docs-Русский-darkblue)](./README.ru.md) [![Українська документація](https://img.shields.io/badge/docs-Українська-lightblue)](./README.uk.md) [![Türkçe Doküman](https://img.shields.io/badge/docs-Türkçe-blue)](./README.tr.md) [![Arabic Documentation](https://img.shields.io/badge/docs-Arabic-white)](./README.ar.md) [![Tiếng Việt](https://img.shields.io/badge/docs-Tiếng%20Việt-red)](./README.vi.md)

## مقدمة

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/fe65df0c-1d8e-47e3-a984-2911babd964d"
           alt="الميزة 1"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6bffc14d-1a11-4558-a1a1-554bdfa1b247"
           alt="الميزة 2"
           width="100%"
           style="max-width: 100%; height: auto;" />
    </td>
  </tr>
</table>

توفر هذه الإضافة تكاملاً سلساً لـ PlantUML مع Neovim، وتتضمن الميزات التالية:

- **المعاينة في المتصفح**: إنشاء ملفات SVG ومعاينتها في المتصفح الافتراضي عبر خادم محلي
- **معاينة ASCII في الوقت الفعلي**: معاينة مخططات PlantUML كفن ASCII في نافذة Neovim منقسمة باستخدام الهدف UTXT
- **تصدير PNG بدقة عالية**: تصدير المخططات إلى ملفات PNG عالية الدقة باستخدام Inkscape للحصول على صور واضحة جاهزة للنشر
- **صيغ تصدير متعددة**: دعم إنشاء ملفات بصيغ SVG وPNG وUTXT (فن ASCII)
- **إدارة ذكية للنوافذ**: إنشاء وتحديث نوافذ المعاينة بذكاء

## التثبيت والاستخدام

### المتطلبات الأساسية

- **Neovim** >= 0.8.0
- **Java** (مطلوب عند استخدام plantuml.jar)
- **PlantUML** - أحد الخيارات التالية:
  - أمر `plantuml` متاح في PATH، أو
  - ملف `plantuml.jar` (قم بتهيئة المسار في الإعداد)
- **Inkscape** (اختياري، لتصدير PNG بدقة عالية)

### تهيئة نوع الملف

لا يتعرف Neovim على امتدادات الملفات `.puml` و `.uml` بشكل افتراضي. يتضمن مثال lazy.nvim أدناه كشف نوع الملف عبر دالة `init`. بدلاً من ذلك، يمكنك إضافة هذا إلى ملف `init.lua` الخاص بك (قبل إعداد lazy.nvim):

```lua
vim.filetype.add({
  extension = {
    puml = "plantuml",
    uml = "plantuml",
  },
})
```

### التثبيت

#### باستخدام [lazy.nvim](https://github.com/folke/lazy.nvim)

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
  ft = { "plantuml" },  -- تحميل كسول عند فتح ملفات .puml أو .uml
  config = function()
    require("plantuml").setup({
      java_cmd = "java",
      plantuml_jar = nil,        -- مسار ملف plantuml.jar (اختياري إذا كان plantuml في PATH)
      inkscape_cmd = "inkscape",
      server_port = 8080,
      png_dpi = 300,
    })
  end,
  keys = {
    { "<leader>vup", "<cmd>PlantumlPreview<cr>",     desc = "معاينة PlantUML في المتصفح" },
    { "<leader>vuu", "<cmd>PlantumlPreviewUTXT<cr>", desc = "معاينة PlantUML كـ ASCII" },
    { "<leader>vus", "<cmd>PlantumlCreateSVG<cr>",   desc = "إنشاء ملف SVG" },
    { "<leader>vug", "<cmd>PlantumlCreatePNG<cr>",   desc = "إنشاء ملف PNG (دقة عالية)" },
    { "<leader>vut", "<cmd>PlantumlCreateUTXT<cr>",  desc = "إنشاء ملف UTXT" },
  },
}
```

### الاستخدام

1. افتح ملف PlantUML (بالامتداد `.puml` أو `.uml`) في Neovim
2. استخدم الأوامر أو الاختصارات أدناه لمعاينة أو تصدير المخطط الخاص بك

### الأوامر والاختصارات

| الأمر | الاختصار | الوصف |
|-------|----------|-------|
| `:PlantumlPreview` | `<leader>vup` | إنشاء SVG ومعاينته في المتصفح الافتراضي |
| `:PlantumlPreviewUTXT` | `<leader>vuu` | إنشاء UTXT ومعاينته في نافذة منقسمة |
| `:PlantumlCreateSVG` | `<leader>vus` | إنشاء ملف SVG في مجلد `umlout/` |
| `:PlantumlCreatePNG` | `<leader>vug` | إنشاء ملف PNG بدقة عالية (يتطلب Inkscape) |
| `:PlantumlCreateUTXT` | `<leader>vut` | إنشاء ملف UTXT (فن ASCII) |

## الإعدادات

```lua
require('plantuml').setup({
  -- مسار أمر java (الافتراضي: "java")
  java_cmd = "java",
  
  -- مسار ملف plantuml.jar (اختياري، يستخدم plantuml النظام إذا لم يتم تعيينه)
  plantuml_jar = nil,
  
  -- مسار أمر inkscape (الافتراضي: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- منفذ الخادم لمعاينة المتصفح (الافتراضي: 8080)
  server_port = 8080,
  
  -- DPI لتصدير PNG عبر Inkscape (الافتراضي: 300)
  png_dpi = 300,
})
```

### خيارات الإعدادات

| الخيار | النوع | الافتراضي | الوصف |
|--------|------|-----------|-------|
| `java_cmd` | نص | `"java"` | مسار ملف Java التنفيذي (يُستخدم مع `plantuml_jar`) |
| `plantuml_jar` | نص \| nil | `nil` | مسار ملف `plantuml.jar`. إذا كان `nil`، يستخدم أمر `plantuml` النظام |
| `inkscape_cmd` | نص | `"inkscape"` | مسار ملف Inkscape التنفيذي لتحويل PNG |
| `server_port` | رقم | `8080` | منفذ خادم المعاينة المحلي |
| `png_dpi` | رقم | `300` | دقة DPI لتصدير PNG |

## ملاحظات

- **الملفات المؤقتة**: يتم تخزين جميع الملفات المؤقتة في `/tmp/plantuml.nvim/`
- **معاينة المتصفح**: تعمل معاينة SVG عبر خادم HTTP محلي لعرض الملفات المُنشأة
- **ملفات الإخراج**: أوامر `PlantumlCreate*` تحفظ الملفات في `<مجلد-المشروع>/umlout/`:
  - تكتشف الإضافة مجلد المشروع من خلال إيجاد أول مجلد أب يحتوي على `.git`
  - إذا لم يُعثر على `.git`، يُستخدم دليل العمل الحالي للمخزن المؤقت
- **إدارة النوافذ الذكية**: `PlantumlPreviewUTXT` يدير نافذة المعاينة بذكاء:
  - ينشئ نافذة منقسمة جديدة إذا لم تكن هناك نافذة معاينة موجودة
  - يحدث المخزن المؤقت الموجود إذا كانت نافذة المعاينة مفتوحة بالفعل
- **أمر Inkscape**: يستخدم إنشاء PNG أمر Inkscape بالنمط التالي:

  ```bash
  inkscape --export-dpi=300 --export-filename=output.png input.svg
  ```

## الرخصة

رخصة MIT

## حقيقة مذهلة

هذا المشروع هو تجربتي الأولى في استخدام `OpenCode`، وحتى معظم هذا [README.md](../README.md). الجزء الوحيد الذي أنجزته بنفسي بالكامل هو [README_FOR_AGENT.md](../README_FOR_AGENT.md).
