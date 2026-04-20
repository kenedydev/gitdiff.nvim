local state = require("gitdiff.state")
local diff = require("gitdiff.diff")
local signs = require("gitdiff.signs")
local config = require("gitdiff.config")

local M = {}
local timers = {}

local function pipeline(bufnr, fetch_from_git)
	local opts = config.options
	if not opts.enabled then
		return
	end

	local run_logic = function(git_data)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local diff_results = diff.calculate(git_data, lines)
		signs.render(bufnr, diff_results, opts.signs)
	end

	if fetch_from_git then
		state.update(bufnr, run_logic)
	else
		run_logic(state.get(bufnr))
	end
end

function M.setup(opts)
	config.setup(opts)
	signs.setup_highlights()

	local group = vim.api.nvim_create_augroup("GitDiff", { clear = true })

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
		group = group,
		callback = function(args)
			pipeline(args.buf, true)
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
					pipeline(args.buf, false)
				end)
			)
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
