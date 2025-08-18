-- Set up package path to find local modules
package.path = package.path .. ';' .. vim.fn.getcwd() .. '/lua/?.lua;' .. vim.fn.getcwd() .. '/lua/?/init.lua'

-- Load Neopilot config
local ok, config = pcall(require, 'neopilot.config')
if not ok then
  print("Error loading neopilot.config:", config)
  return
end

-- Initialize config with default values if not already done
if not config.performance then
  config.performance = {
    enable_telemetry = true,
    telemetry_sample_rate = 1.0,
    max_memory_usage_mb = 500,
  }
end

-- Load and run the test module
local test_ok, test_module = pcall(require, 'tests.performance.run_all_tests')
if not test_ok then
  print("Error loading test module:", test_module)
  return
end

print("Tests completed successfully!")
