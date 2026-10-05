-- Validate the selected real configuration, not CI host hardware.
local home = assert(os.getenv('HOME'))
local config_dir = home .. '/.config/awesome/'
package.path = config_dir .. '?.lua;' .. config_dir .. '?/init.lua;' .. package.path
package.loaded['gears.filesystem'] = { get_configuration_dir = function() return config_dir end }
local config = require('configuration.config')
local expected = os.getenv('AWESOME_TEST_PROFILE')
assert(config.machine == 'laptop' or config.machine == 'imac' or config.machine == 'desktop',
    'Configuration must declare a supported machine profile')
if expected then assert(config.machine == expected, 'CI did not select the requested machine configuration') end
if config.machine == 'imac' then
    assert(config.module.lockscreen.fingerprint_unlock == false, 'iMac must not enable laptop fingerprint authentication')
end
print('selected machine profile tests passed: ' .. config.machine)
