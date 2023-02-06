return require("telescope").register_extension {
    setup = function(ext_config, config) require("notepad").setup(ext_config) end,
    exports = {notepad = require("notepad").pick_action}
}
