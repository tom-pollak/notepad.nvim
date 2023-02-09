# notepad.nvim

Super simple telescope extension to jot notes

<img width="650" alt="notepad nvim_panel" src="https://user-images.githubusercontent.com/26611948/217779309-e9aaa9d6-a9ec-40de-99ef-727063b5361c.png">

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
