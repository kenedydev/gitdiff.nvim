local state = require("gitdiff.state")
local ui = require("gitdiff.ui")

local M = {}

M.setup = function(opts)
	ui.setup_highlights()

	local group = vim.api.nvim_create_augroup("GitDiff", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
		group = group,
		callback = function(args)
			state.update(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		callback = function(args)
			ui.schedule_update(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			state.clear(args.buf)
		end,
	})
end

return M
