# Neo-vim setup instructions

1. Complete homebrew installation.

2. Open Nvim
```vim
:Lazy sync
:MasonToolsInstall
```

## Python LSP

`pylsp` resolves Python imports per project, independently of Neovim's working
directory. For installed dependencies, Jedi and mypy prefer the nearest project
`.venv/bin/python`, then `~/.local/share/venv`, then already-built Bazel packages.
Workspace sources and generated modules are project code. The server and its
plugins can stay in the shared venv; nothing needs to be activated or installed
in the project just to start the LSP.

In a Bazel workspace, files in the same BUILD package share a client. It reads
that package's `*.runfiles` and `*.venv` under `bazel-bin` (or `bazel-out/*/bin`
if the convenience link is missing), including generated modules, wheel
`site-packages`, and extracted `3rdparty/bazel/pip/*/lib` directories. Without
package runfiles it can use those extracted wheels from the workspace build.
It never runs Bazel. Build the target first, then use `:lsp restart pylsp` to
pick up new outputs or a newly created environment. Missing packages and
missing type stubs are still reported.

In a Python buffer, `<leader>lf` formats and sorts imports using
`python-lsp-ruff`'s import rule (`I`); it does not remove unused imports.

## Unit Tests

Unit tests are located in `tests/` directory and use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) busted-style testing.

### Running Tests Locally

```bash
# Run all tests (respects .testignore blacklist)
./tests/run_all_tests.sh

# Run a specific test file
./tests/run_all_tests.sh test_telescope.lua

# Run all tests, ignoring the blacklist
./tests/run_all_tests.sh --all
```

### Blacklisting Tests

To exclude specific tests from running, create a `.testignore` file in the `tests/` directory:

```bash
# tests/.testignore
test_remote_nvim.lua
test_neocodeium.lua
```

### CI Integration

Tests run automatically on GitHub Actions when changes are pushed to `.config/nvim/`. The CI workflow:

1. Runs a one-time setup (installs plugins, treesitter parsers)
2. Dynamically discovers all `test_*.lua` files
3. Respects `.testignore` blacklist
4. Runs each test file in parallel as separate jobs
