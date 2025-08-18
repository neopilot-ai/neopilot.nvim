# MoveBetter Plugin for Neovim

MoveBetter is a Neovim plugin designed to help you improve your efficiency with Vim movements.

## Features

- **Track Movements:** Keeps track of movement commands like `hjkl`, `w`, `b`, `e`, etc.
- **Suggestions:** Offers suggestions for more efficient movement commands.

## Setup

```lua
require('move_better').setup()
```

## Example Key Mappings

```lua
-- Show movement suggestions
vim.keymap.set('n', '<leader>ms', function()
    require('move_better.suggestions').suggest_alternatives()
end, { desc = 'Show movement suggestions' })
```

## How it Works

The plugin tracks movement commands while you edit files and prints the movement count for the current buffer to the command line.

Suggestions for more efficient movement commands will be displayed based on the observed usage patterns.

## Planned Features

- More detailed tracking of movement efficiency
- Advanced suggestions based on usage patterns
- Customizable thresholds for suggestions

## Contributing

Feel free to contribute by opening issues or submitting pull requests to improve the plugin.


