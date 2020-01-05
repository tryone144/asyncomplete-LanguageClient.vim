LSP source for asyncomplete.vim - LanguageClient-neovim
=======================================================

Provide [Language Server Protocol](https://github.com/Microsoft/language-server-protocol) autocompletion source for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim) from [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim).

## Installing ([vim-plug](https://github.com/junegunn/vim-plug))

1. Install [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim#quick-start).
2. Install [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim#installing) + this completion source.

```vim
Plug 'autozimu/LanguageClient-neovim', {'branch': 'next', 'do': 'bash install.sh'}
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'tryone144/asyncomplete-LanguageClient.vim'
```

### Completion sources

This plugin does not provide any completions on its own but uses [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim) to query them from a language server.
Refer to the LanguageClient-neovim [Dokumentation](https://github.com/autozimu/LanguageClient-neovim/blob/next/INSTALL.md#5-configure-this-plugin) on how to register new language servers.

### Registration

Sources will be registered automatically when the language server has been started.
To add more sources see [Completion Sources](#completion-sources).


# Development

The following features are currently not implemented:
- [ ] Add option to disable loading of this plugin
- [ ] Add support for whitelist/blacklist on when to register the LanguageClient
- [ ] Add option to specify source priority (globally, or for each filetype)
- [x] Register the LanguageClient separately for each filetype

If you want to contribute to the development feel free to submit a PR.

---

### Legal

Copyright 2020 Bernd Busse @tryone144

This plugin is released under the [MIT license](./LICENSE).
