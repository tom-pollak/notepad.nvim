M = {}

M.options = {}

local defaults = {
	notes_directory = os.getenv("HOME") .. "/notes",
	file_extension = ".md",
}

local known_headings = {
	md = { "---", "title: <TITLE>", "tags: <TAGS>", "---" },
	org = {
		"#+title:      <TITLE>",
		"#+date:       <DATE>",
		"#+filetags:   <TAGS>",
	},
	norg = {
		"@document.meta",
		"title: <TITLE>",
		"created: <DATE>",
		"@end",
	},
}

local text_to_tags = function(raw_tags)
	local tags = {}
	for i in string.gmatch(raw_tags, "([^%s* %s*]+)") do
		table.insert(tags, i)
	end
	return tags
end

function table.shallow_copy(t)
	local t2 = {}
	for k, v in pairs(t) do
		t2[k] = v
	end
	return t2
end

M.new = function(file_extension)
	local title = ""
	file_extension = file_extension or M.options.file_extension
	vim.ui.input({ prompt = "Enter title: " }, function(input)
		title = input
	end)
	if title == nil then
		print("The title is required.")
		return
	end
	title = title.gsub(title, "%s+$", "")

	local raw_tags = nil

	vim.ui.input({ prompt = "Enter tags: " }, function(input)
		raw_tags = input
	end)

	local tags = {}
	if raw_tags ~= nil then
		tags = text_to_tags(raw_tags)
	end

	M._open(title, tags, file_extension)
end

M.rename = function()
	local current = vim.api.nvim_buf_get_name(0)
	local title, extension = M._deconstruct_slug(current)

	vim.ui.input({
		prompt = "Enter title (press enter to reuse " .. title .. "): ",
	}, function(input)
		title = input or title
	end)

	local new_name = M._build_slug(title, extension)
	new_name = M.options.notes_directory .. "/" .. new_name
	os.rename(current, new_name)
	vim.api.nvim_buf_set_name(0, new_name)
	vim.cmd("e")
end

M._open = function(title, tags, extension)
	local file_name = M._build_slug(title, extension)
	local file_path = M.options.notes_directory .. "/" .. file_name
	vim.cmd("e " .. file_path)

	local file_exists = vim.fn.filereadable(vim.fn.expand(file_path))
	if file_exists == 1 then
		print("\nFile exists, opening")
	else
		for ext, template in pairs(known_headings) do
			if vim.endswith(file_name, "." .. ext) then
				local subbed_template = table.shallow_copy(template)
				for i, _ in ipairs(subbed_template) do
					subbed_template[i] = subbed_template[i]:gsub("<TITLE>", title)
					subbed_template[i] =
						subbed_template[i]:gsub("<TAGS>", table.concat(tags, ", ")):gsub("^%s*(.-)%s*$", "%1")
				end
				vim.api.nvim_put(subbed_template, "l", false, true)
				break
			end
		end
	end
end

M._build_slug = function(title, extension)
	local normalized_name = string.lower(title)
	normalized_name = string.gsub(normalized_name, "%s+", "_")
	local file_name = normalized_name .. extension
	return file_name
end

M._deconstruct_slug = function(filename)
	local title, extension = filename:match("([^-].+)(%..+)$")
	title = title or ""
	return title, extension
end

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
end

M.find_notes = function()
	require("telescope.builtin").find_files({
		prompt_title = "Find note",
		cwd = M.options.notes_directory,
	})
end

M.search_notes = function()
	require("telescope.builtin").live_grep({
		prompt_title = "Grep notes",
		cwd = M.options.notes_directory,
		disable_coordinates = true,
	})
end

M.search_tags = function()
	require("telescope.builtin").live_grep({
		prompt_title = "Search tags",
		cwd = M.options.notes_directory,
		default_text = "tags:.*",
		disable_coordinates = true,
		use_regex = true,
	})
end

M.pick_action = function(opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local commands = { "find note", "new note", "search notes", "search tags", "rename note" }
	local funcs = { M.find_notes, M.new, M.search_notes, M.search_tags, M.rename }
	opts = opts or require("telescope.themes").get_ivy()
	pickers
		.new(opts, {
			prompt_title = "Notepad",
			finder = finders.new_table({
				results = commands,
			}),
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					funcs[selection.index]()
				end)
				return true
			end,
		})
		:find()
end

return M
