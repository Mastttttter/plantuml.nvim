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

## notice

- All the temp file will save in `/tmp/plantuml.nvim/` folder
- the SVG file preview feature will realize via setup a local Node.js server
- the all CreateXXX feature will create the target file in separate folder in the `project-folder/umlout/`, The first parent directory that contains ".git" will be recognized as `project-folder`. If no `.git` found, the buffer's current folder will be recognized as `project-folder`
- the PlantumlpreviewUTXT feature will intelligently create window, that means, if no preview window exists, it will create a window, otherwise, it will update the buffer only.
- the inkscape cmd will like `inkscape --export-dpi=400 --export-filename=readerAccount.png ./readerAccount.svg`
