M = {}

M.options = {}

local defaults = {
    notes_directory = os.getenv("HOME") .. "/notes",
    file_extension = ".md",
    metadata = {"tags"},
    enable_metadata = true,
    file_ignore_patterns = {".git/", ".DS_Store"}
}

function table.shallow_copy(t)
    local t2 = {}
    for k, v in pairs(t) do t2[k] = v end
    return t2
end

local function insert_metadata(file_data)
    local template_data = {"---"}
    for t, v in pairs(file_data) do
        table.insert(template_data, t .. ": " .. v)
    end
    table.insert(template_data, "---")
    vim.api.nvim_put(template_data, "l", false, true)
end

local function build_slug(title, extension)
    local normalized_name = string.lower(title)
    normalized_name = string.gsub(normalized_name, "%s+", "_")
    local file_name = normalized_name .. extension
    return file_name
end

local function open(file_data, extension)
    local title = file_data.title
    if title == nil then
        print("The title is required.")
        return
    end

    local file_name = build_slug(title, extension)
    local file_path = M.options.notes_directory .. "/" .. file_name
    vim.cmd("e " .. file_path)

    local file_exists = vim.fn.filereadable(vim.fn.expand(file_path))
    if file_exists == 1 then
        print("\nFile exists, opening")
    else
        if M.options.enable_metadata then insert_metadata(file_data) end
    end
end

M.new = function()
    local title = ""
    local file_extension = M.options.file_extension or ".md"
    vim.ui.input({prompt = "Enter title: "}, function(input) title = input end)
    if title == nil then
        print("The title is required.")
        return
    end
    title = title.gsub(title, "%s+$", "")

    local file_data = {title = title}
    for i, d in ipairs(M.options.metadata) do
        local value = ""
        vim.ui.input({prompt = "Enter " .. d .. ": "},
                     function(input) value = input end)
        if value ~= nil then file_data[d] = value end
    end
    open(file_data, file_extension)
end

M.rename = function()
    local current = vim.api.nvim_buf_get_name(0)
    local title, extension = M._deconstruct_slug(current)

    vim.ui.input({
        prompt = "Enter title (press enter to reuse " .. title .. "): "
    }, function(input) title = input or title end)

    local new_name = build_slug(title, extension)
    new_name = M.options.notes_directory .. "/" .. new_name
    os.rename(current, new_name)
    vim.api.nvim_buf_set_name(0, new_name)
    vim.cmd("e")
end

M.setup = function(opts)
    M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

M.find_notes = function()
    require("telescope.builtin").find_files({
        prompt_title = "Find note",
        cwd = M.options.notes_directory,
        file_ignore_patterns = M.options.file_ignore_patterns
    })
end

M.search_notes = function()
    require("telescope.builtin").live_grep({
        prompt_title = "Grep notes",
        cwd = M.options.notes_directory,
        disable_coordinates = true,
        file_ignore_patterns = M.options.file_ignore_patterns
    })
end

M.search_tags = function()
    require("telescope.builtin").live_grep({
        prompt_title = "Search tags",
        cwd = M.options.notes_directory,
        default_text = "tags:.*",
        disable_coordinates = true,
        use_regex = true,
        file_ignore_patterns = M.options.file_ignore_patterns
    })
end

M.pick_action = function(opts)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local commands = {
        "find note", "new note", "search notes", "search tags", "rename note"
    }
    local funcs = {M.find_notes, M.new, M.search_notes, M.search_tags, M.rename}
    opts = opts or require("telescope.themes").get_ivy()
    pickers.new(opts, {
        prompt_title = "Notepad",
        finder = finders.new_table({results = commands}),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                funcs[selection.index]()
            end)
            return true
        end
    }):find()
end

return M
