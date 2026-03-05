# neovim plantuml plugin

this plugin support:

- plantuml preview use default browser
- realtime plantuml utxt target preview in neovim window
- plantuml high dpi picture generate

## commands

- PlantumlPreview: use plantuml to generate temp SVG file and open it in default browser
- PlantumlPreviewUTXT: use plantuml to generate temp TXT file, split a window in neovim to right and open this generated file
- PlantumlCreateSVG: use plantuml to create SVG file
- PlantumlCreatePNG: use plantuml to create SVG file, then use inkscape to convert the SVG file to PNG file
- PlantumlCreateUTXT: use plantuml to create UTXT file

## usage

open a plantuml file (.puml .uml) in neovim buffer, then use the commands

## configuration

```lua
require('plantuml').setup({
  -- Path to java command (default: "java")
  java_cmd = "java",
  
  -- Path to plantuml.jar file (optional, uses system plantuml if not set)
  plantuml_jar = nil,
  
  -- Path to inkscape command (default: "inkscape")
  inkscape_cmd = "inkscape",
  
  -- Server port for preview (default: 8912)
  server_port = 8912,
  
  -- DPI for PNG export via Inkscape (default: 800)
  png_dpi = 800,
})
```

## notice

- All the temp file will save in `/tmp/plantuml.nvim/` folder
- the SVG file preview feature will realize via setup a local Node.js server
- the all CreateXXX feature will create the target file in separate folder in the `project-folder/umlout/`, The first parent directory that contains ".git" will be recognized as `project-folder`. If no `.git` found, the buffer's current folder will be recognized as `project-folder`
- the PlantumlpreviewUTXT feature will intelligently create window, that means, if no preview window exists, it will create a window, otherwise, it will update the buffer only.
- the inkscape cmd will like `inkscape --export-dpi=400 --export-filename=readerAccount.png ./readerAccount.svg`

## points about :PlantumlPreview

the page user see should contains title(filename), and the SVG should in center of the page, the page should remind user save the buffer to trigger automatically update the svg file display and the time from last update to now.

when user change to another plantuml buffer and trigger the :PlantumlPreview cmd and the previous server exists, the server should change to display the new diagram

when the server need to shutdown, user's browser page should close itself

the browser page only update the SVG part, the time part and other essential part of the page, not the entire page.
