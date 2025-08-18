# Lua Refactoring Library

A Lua refactoring library based on Martin Fowler's "Refactoring" book, integrated into the neopilot.nvim plugin.

## Overview

This library provides various refactoring techniques to improve code structure and readability. It implements classic refactoring patterns from Martin Fowler's seminal work on refactoring.

## Available Refactorings

### 1. Extract Method

Turn a fragment of code into a method with a name that explains its purpose.

```lua
local refactorings = require('refactorings')

-- Extract lines 10-15 into a new method called 'calculate_total'
refactorings.extract_method(10, 15, 'calculate_total')

-- Extract current visual selection
refactorings.extract_method_visual('process_data')
```

### 2. Rename Variable

Change the name of a variable to better express its purpose.

```lua
-- Rename 'x' to 'total_count' in the current function
refactorings.rename_variable('x', 'total_count')

-- Rename with specific scope ('buffer', 'function', 'local')
refactorings.rename_variable('temp', 'user_input', nil, 'buffer')

-- Interactive rename of variable under cursor
refactorings.rename_variable_under_cursor()
```

### 3. Inline Temp

Replace a temporary variable with the expression that assigns to it.

```lua
-- Inline the variable 'temp_result'
refactorings.inline_temp('temp_result')

-- Inline variable under cursor
refactorings.inline_temp_under_cursor()

-- Interactive inline with prompt
refactorings.inline_temp_interactive()
```

## Usage

### Basic Setup

```lua
local refactorings = require('refactorings')
refactorings.setup({
    -- Configuration options (future)
})
```

### Example Key Mappings

```lua
-- Extract method from visual selection
vim.keymap.set('v', '<leader>rem', function()
    local method_name = vim.fn.input('Method name: ')
    if method_name ~= '' then
        require('refactorings').extract_method_visual(method_name)
    end
end, { desc = 'Extract method' })

-- Rename variable under cursor
vim.keymap.set('n', '<leader>rrv', function()
    require('refactorings').rename_variable_under_cursor()
end, { desc = 'Rename variable' })

-- Inline temporary variable
vim.keymap.set('n', '<leader>rit', function()
    require('refactorings').inline_temp_under_cursor()
end, { desc = 'Inline temp' })
```

## Supported Refactoring Patterns

This library implements refactoring patterns from Martin Fowler's book:

- ✅ **Extract Method** - Turn a fragment of code into a method
- ✅ **Rename Variable** - Change variable names for clarity
- ✅ **Inline Temp** - Replace temporary variables with their expressions
- 🚧 **Extract Function** - Similar to extract method but for standalone functions
- 🚧 **Inline Function** - Replace function calls with function body
- 🚧 **Extract Variable** - Turn expressions into well-named variables
- 🚧 **Move Function** - Move functions between classes/modules
- 🚧 **Substitute Algorithm** - Replace algorithm with clearer one

Legend: ✅ Implemented, 🚧 Planned

## Language Support

Currently optimized for Lua code, but the patterns can be extended to support other languages by modifying the parsing logic.

## Contributing

When adding new refactoring methods:

1. Create a new module in the `lua/refactorings/` directory
2. Implement the core refactoring logic
3. Add the module to `init.lua`
4. Update the documentation
5. Follow Martin Fowler's refactoring catalog for consistency

## References

- [Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html) by Martin Fowler
- [Refactoring Catalog](https://refactoring.com/catalog/) - Online catalog of refactoring patterns
