# notepad.nvim

Super simple telescope extension to jot notes

- create & update notes
- tags
- telescope fzf

## Install

```lua
use {
  "nvim-telescope/telescope.nvim",
    requires = { "/Users/tom/projects/notepad.nvim" },
    config = function()
      local telescope = require "telescope"
      telescope.setup {
        telescope.load_extension "notepad"
      }
    end
}
```

## Usage

`:Telescope notepad`

---

Based on https://github.com/oem/arachne.nvim
