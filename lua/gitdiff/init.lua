local git = require("gitdiff.git")
local diff = require("gitdiff.diff")
local signs = require("gitdiff.signs")
local config = require("gitdiff.config")

local M = {
	cache = {},
}

local timers = {}

local function pipeline(bufnr)
	local git_data = M.cache[bufnr]
	if not git_data then
		return
	end

	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local hunks_data = diff.get_hunks_data(git_data, buffer_lines)
	signs.render(bufnr, hunks_data, config.options.signs)
end

function M.setup(opts)
	config.setup(opts)
	signs.setup()

	local group = vim.api.nvim_create_augroup("GitDiff", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
		group = group,
		callback = function(args)
			git.fetch(args.buf, function(git_data)
				M.cache[args.buf] = git_data
				pipeline(args.buf)
			end)
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = group,
		callback = function(args)
			if not timers[args.buf] then
				timers[args.buf] = vim.uv.new_timer()
			end

			local t = timers[args.buf]
			t:stop()
			t:start(
				200,
				0,
				vim.schedule_wrap(function()
					pipeline(args.buf)
				end)
			)
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		callback = function(args)
			M.cache[args.buf] = nil

			if timers[args.buf] then
				timers[args.buf]:close()
				timers[args.buf] = nil
			end
		end,
	})
end

return M
