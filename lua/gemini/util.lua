local M = {}

M.borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

M.open_window = function(content, options)
	local popup = require("plenary.popup")
	options.borderchars = M.borderchars
	local win_id, result = popup.create(content, options)
	local bufnr = vim.api.nvim_win_get_buf(win_id)
	local border = result.border
	vim.api.nvim_set_option_value("ft", "markdown", { buf = bufnr })
	vim.api.nvim_set_option_value("wrap", true, { win = win_id })

	local close_popup = function()
		vim.api.nvim_win_close(win_id, true)
	end

	local keys = { "<C-q>", "q" }
	for _, key in pairs(keys) do
		vim.api.nvim_buf_set_keymap(bufnr, "n", key, "", {
			silent = true,
			callback = close_popup,
		})
	end
	return win_id, bufnr, border
end

M.manage_gemini_buffer = function(target_name)
	local gemini_chat_bufnr = vim.fn.bufnr(target_name)
	local gemini_chat_winid = nil

	-- Check if the buffer exists and is displayed in any window
	if gemini_chat_bufnr ~= -1 then
		for _, winid in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_get_buf(winid) == gemini_chat_bufnr then
				gemini_chat_winid = winid
				break
			end
		end
	end

	if gemini_chat_winid then
		-- Buffer is open in a window, switch focus to it
		vim.api.nvim_set_current_win(gemini_chat_winid)
		print("Switched to Gemini Chat window.")
	else
		-- Buffer is not open in a window, close it if it exists and open a new one
		if gemini_chat_bufnr ~= -1 then
			-- Close the buffer (forcefully if needed)
			vim.cmd("silent! bwipeout! " .. target_name)
		end

		-- Open a new vertical split with the gemini-chat.md file
		vim.cmd("vsplit " .. target_name)
		print("Opened new Gemini Chat window.")
	end

	vim.cmd("wincmd L")
	return vim.api.nvim_get_current_buf()
end

M.treesitter_has_lang = function(bufnr)
	local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
	local lang = vim.treesitter.language.get_lang(filetype)
	return lang ~= nil
end

M.find_node_by_type = function(node_type)
	local node = vim.treesitter.get_node()
	while node do
		local type = node:type()
		if string.find(type, node_type) then
			return node
		end

		local parent = node:parent()
		if parent == node then
			break
		end
		node = parent
	end
	return nil
end

M.debounce = function(callback, timeout)
	local timer = nil
	local f = function(...)
		local t = { ... }
		local handler = function()
			callback(unpack(t))
		end

		if timer ~= nil then
			timer:stop()
		end
		timer = vim.defer_fn(handler, timeout)
	end
	return f
end

M.table_get = function(t, id)
	if type(id) ~= "table" then
		return M.table_get(t, { id })
	end
	local success, res = true, t
	for _, i in ipairs(id) do
		success, res = pcall(function()
			return res[i]
		end)
		if not success or res == nil then
			return
		end
	end
	return res
end

M.is_blacklisted = function(blacklist, filetype)
	for _, ft in ipairs(blacklist) do
		if string.find(filetype, ft, 1, true) ~= nil then
			return true
		end
	end
	return false
end

M.strip_code = function(text)
	local code_blocks = {}
	local pattern = "```(%w+)%s*(.-)%s*```"
	for _, code_block in text:gmatch(pattern) do
		table.insert(code_blocks, code_block)
	end
	return code_blocks
end

return M
