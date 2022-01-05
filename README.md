# TLA+/PlusCal support for NeoVim
`tla.nvim` is a Lua plugin built to provide IDE-like experience while developing
[TLA+](https://lamport.azurewebsites.net/tla/tla.html) and [PlusCal](https://learntla.com/pluscal/) specifications. Powered by official [TLA tooling](https://github.com/tlaplus/tlaplus).

## Features
- [x] TLA tools installation
- [x] PlusCal to TLA+ translation
- [x] TLC model-checking
- [x] TLC output parsing and displaying
- [ ] state graph dump to [dot](https://en.wikipedia.org/wiki/DOT_(graph_description_language))-formatted file
- [ ] code snippets
- [ ] diagnostics via LSP mechanisms
- [ ] worksheets and REPL
- [ ] PDF generation

## Prerequisites
- Neovim >= v0.5.0. While `tla.nvim` will aim to
  always work with the latest stable version of Neovim, there is no guarantee
  of compatibility with older versions.
- Java >= 8. If you have the `JAVA_HOME` environment variable, plugin will
  work from the start. Otherwise you should specify the location of Java
  installation.
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). Make sure to have
  this installed

## Installation
1. Include the plugin to your config. For example, using [packer](https://github.com/wbthomason/packer.nvim):
```
use({"susliko/tla.nvim", requires = { "nvim-lua/plenary.nvim" }})
```
2. Setup the plugin in your `init.lua`:
```
require("tla").setup()
```
This is equivalent to:
```
require("tla").setup{
  -- Path to java binary directory. $JAVA_HOME by default
  java_executable = "path/to/java/bin",

  -- Options passed to the jvm when running tla2tools
  java_opts = { '-XX:+UseParallelGC' },

  -- Only needed if you don't wont automatic tla2tools installation
  tla2tools = "path/to/tla2tools.jar", 
}
```


## Commands
| Command | Lua API | Description |
| --- | --- | --- |
| `TlaInstall` | `require"tla.install".install_tla2tools()` | Downloads latest tla2tools release. Rewrites existing |
| `TlaTranslate` | `require"tla".translate()` | Translates PlusCal code in the current buffer into TLA+ code |
| `TlaCheck` | `require"tla".check()` |Model-checks TLA+ code in the current buffer and displays results |


## Demo
TODO gifs

## Integrations
### Syntax Highlighting
[tree-sitter](https://github.com/nvim-treesitter/nvim-treesitter) usage for syntax highlighting is encouraged.       
[The grammar](https://github.com/tlaplus-community/tree-sitter-tlaplus) supports only TLA+ syntax at the moment, but PlusCal syntax is on its way :rocket:.
