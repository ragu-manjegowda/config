# Neo-vim setup instructions

1. Complete homebrew installation.

2. Open Nvim
```vim
:Lazy sync
:MasonToolsInstall
```

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
