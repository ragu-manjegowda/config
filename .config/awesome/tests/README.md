# AwesomeWM Configuration Tests

Comprehensive test suite for AwesomeWM dotfiles configuration.

## Overview

This test suite validates:
- ✅ Lua syntax and configuration loading
- ✅ **awmtt (AwesomeWM Test Tool)** - Real runtime verification
- ✅ Bash script correctness and executability
- ✅ Display configuration consistency
- ✅ Module structure and imports
- ✅ Integration between components
- ✅ Security and best practices

## Running Tests

### Local Testing

Run all tests locally:
```bash
cd ~/.config/awesome/tests
./run_all_tests.sh
```

Run individual tests:
```bash
lua test_display_config.lua
lua test_config_structure.lua
lua test_read_display_config.lua
```

### Testing with awmtt (Advanced)

Test your config in a real AwesomeWM instance:
```bash
# Install awmtt from AUR
yay -S awmtt

# Test your configuration
awmtt start -C ~/.config/awesome/rc.lua

# Or use Xephyr for a nested window
Xephyr :1 -screen 1920x1080 &
DISPLAY=:1 awesome -c ~/.config/awesome/rc.lua
```

### CI/CD Testing

Tests run automatically on GitHub when you push changes to:
- `.config/awesome/**` - Any AwesomeWM config changes
- `.github/workflows/**` - Workflow changes

View test results in the "Actions" tab of your GitHub repository.

## Test Structure

### Unit Tests (Lua)

Located in `tests/test_*.lua`:

1. **`test_display_config.lua`**
   - Validates display configuration structure
   - Checks DPI, resolution, and position values
   - Ensures primary and external displays are configured correctly
   - Tests value formats and ranges

2. **`test_config_structure.lua`**
   - Validates overall config.lua structure
   - Checks all major configuration sections
   - Verifies widget and module configurations
   - Tests keyboard, network, and other settings

3. **`test_read_display_config.lua`**
   - Tests the read-display-config utility
   - Validates bash export format
   - Ensures consistency with config.lua
   - Tests bash sourcing capability

### Integration Tests (Bash)

Run via `run_all_tests.sh`:

1. **Script Executability**
   - Verifies all utilities have executable permissions
   - Checks for proper shebangs

2. **Lua Syntax Validation**
   - Runs `luac -p` on all Lua files
   - Excludes third-party libraries

3. **Common Issues Check**
   - Scans for world-writable files
   - Identifies potential security issues

## GitHub Actions Workflow

### Jobs

The CI/CD pipeline consists of 7 jobs:

1. **lua-syntax-check** 
   - Installs Lua and luacheck on Arch Linux
   - Validates Lua syntax across all files
   - Runs luacheck with AwesomeWM globals

2. **awesome-config-load** ⭐ **Enhanced with awmtt**
   - Installs AwesomeWM from awesome-git (AUR)
   - Runs `awesome --check` for syntax validation
   - **Installs and runs awmtt for real runtime testing**
   - Verifies AwesomeWM actually starts with your config
   - Tests awesome-client connectivity
   - Ensures clean startup without errors

3. **bash-scripts-validation**
   - Installs and runs shellcheck
   - Validates all bash scripts
   - Checks script permissions

4. **display-config-test**
   - Tests display configuration reading
   - Validates config structure
   - Ensures bash/Lua consistency

5. **module-imports-test**
   - Tests module imports
   - Validates dependencies

6. **integration-tests**
   - Tests script integration
   - Validates config sourcing
   - Ensures components work together

7. **security-scan**
   - Scans for hardcoded secrets
   - Checks for common security issues
   - Identifies TODOs and FIXMEs

8. **test-summary**
   - Aggregates all test results
   - Provides final pass/fail status

### awmtt Testing

The `awesome-config-load` job now includes **awmtt** for comprehensive testing:

```yaml
- name: Install awmtt from AUR
- name: Test configuration with awmtt
  # Starts Xvfb
  # Launches AwesomeWM with your config
  # Verifies it starts successfully
  # Tests awesome-client communication
  # Clean shutdown
```

This ensures your configuration not only has valid syntax, but **actually runs** in a real AwesomeWM environment.

### Triggers

Tests run on:
- **Push** to main/master/develop branches
- **Pull requests** to main/master/develop
- **Manual trigger** via workflow_dispatch

### Dependencies

Test jobs run in sequence where needed:
```
lua-syntax-check
    ├─> awesome-config-load (with awmtt) ⭐
    ├─> display-config-test
    │       └─> integration-tests
    └─> module-imports-test
            └─> integration-tests

bash-scripts-validation
    └─> integration-tests

All jobs ──> test-summary
```

## Adding New Tests

### Creating a Lua Unit Test

```lua
#!/usr/bin/env lua
local TEST_NAME = "My New Tests"
local tests_passed = 0
local tests_failed = 0

-- Setup
local home = os.getenv("HOME")
package.path = home .. "/.config/awesome/?.lua;" .. package.path
package.loaded['gears.filesystem'] = {
    get_configuration_dir = function()
        return home .. "/.config/awesome/"
    end
}

-- Helper functions
local function assert_test(condition, test_name, message)
    if condition then
        print("  ✓ " .. test_name)
        tests_passed = tests_passed + 1
    else
        print("  ✗ " .. test_name)
        if message then print("    " .. message) end
        tests_failed = tests_failed + 1
    end
end

-- Your tests here
print("\n" .. TEST_NAME)
print(string.rep("=", 50))

assert_test(true, "example test")

-- Summary
print("\n" .. string.rep("=", 50))
print(string.format("Results: %d passed, %d failed", tests_passed, tests_failed))
os.exit(tests_failed == 0 and 0 or 1)
```

Save as `tests/test_your_feature.lua` and make it executable.

### Adding to GitHub Actions

Edit `.github/workflows/awesome-wm-tests.yml` and add your test job:

```yaml
your-feature-test:
  name: Your Feature Tests
  runs-on: ubuntu-latest
  container:
    image: archlinux:latest
  needs: lua-syntax-check  # Optional dependency
  steps:
    - name: Checkout dotfiles
      uses: actions/checkout@v4
    
    # Your test steps here
```

## Best Practices

1. **Keep tests fast** - Tests should complete in < 5 minutes
2. **Mock external dependencies** - Don't rely on network or hardware
3. **Use descriptive names** - Test names should explain what they validate
4. **Test edge cases** - Include boundary conditions and error cases
5. **Keep tests isolated** - Tests shouldn't depend on each other
6. **Document assumptions** - Comment why tests exist and what they validate
7. **Test with awmtt locally** - Catch runtime issues before pushing

## Troubleshooting

### Local test failures

1. Check Lua version: `lua -v` (should be 5.3+)
2. Verify config syntax: `awesome --check`
3. Test with awmtt: `awmtt start -C ~/.config/awesome/rc.lua`
4. Check file permissions: `ls -la utilities/`
5. Review error messages in test output

### CI test failures

1. View detailed logs in GitHub Actions tab
2. Check which job failed in the workflow
3. Review the "Annotations" section for specific errors
4. Re-run failed jobs if needed
5. Check awmtt output for runtime errors

### Common Issues

**Issue**: `module 'gears.filesystem' not found`
**Solution**: Tests mock this module - ensure mock is set up correctly

**Issue**: `luacheck: too many warnings`
**Solution**: Add exceptions in workflow or fix code style

**Issue**: `shellcheck errors`
**Solution**: Fix script issues or add exclusions with `-e SCXXXX`

**Issue**: `awmtt timeout or crash`
**Solution**: Check for missing dependencies or config errors in startup

## Continuous Improvement

This test suite should evolve with your configuration:

- Add tests when adding new features
- Update tests when changing existing functionality
- Remove obsolete tests when refactoring
- Increase coverage for critical components
- Test new configurations with awmtt before committing

## Resources

- [AwesomeWM API Documentation](https://awesomewm.org/apidoc/)
- [awmtt Documentation](https://github.com/awesomeWM/awesome/wiki/Debugging)
- [luacheck Documentation](https://luacheck.readthedocs.io/)
- [shellcheck Wiki](https://www.shellcheck.net/wiki/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Arch Linux CI Best Practices](https://wiki.archlinux.org/title/Continuous_integration)
