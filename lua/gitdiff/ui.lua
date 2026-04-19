local diff = require("gitdiff.diff")
local ns_id = vim.api.nvim_create_namespace("gitdiff_signs")
local debounce_timers = {}

local M = {}

function M.setup_highlights()
	vim.api.nvim_set_hl(0, "GitDiffAdd", { fg = "#a6e3a1", bold = true }) -- Verde
	vim.api.nvim_set_hl(0, "GitDiffChange", { fg = "#89b4fa", bold = true }) -- Azul
	vim.api.nvim_set_hl(0, "GitDiffDelete", { fg = "#f38ba8", bold = true }) -- Vermelho

	vim.api.nvim_set_hl(0, "GitDiffStagedAdd", { fg = "#94e2d5", bold = true })
	vim.api.nvim_set_hl(0, "GitDiffStagedChange", { fg = "#b4befe", bold = true })
	vim.api.nvim_set_hl(0, "GitDiffStagedDelete", { fg = "#f38ba8", bold = true })

	vim.api.nvim_set_hl(0, "GitDiffUntracked", { fg = "#cba6f7", bold = true }) -- Roxo
end

local function place_marks(bufnr, diff_data, hl_prefix, priority)
	if not diff_data or type(diff_data) ~= "table" then
		return
	end

	for _, hunk in ipairs(diff_data) do
		local _, count_orig, start_new, count_new = unpack(hunk)

		if count_orig == 0 then
			for i = start_new, start_new + count_new - 1 do
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
					sign_text = "+",
					sign_hl_group = hl_prefix .. "Add",
					priority = priority,
				})
			end
		elseif count_new == 0 then
			local line = math.max(0, start_new - 1)
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, {
				sign_text = "-",
				sign_hl_group = hl_prefix .. "Delete",
				priority = priority,
			})
		else
			for i = start_new, start_new + count_new - 1 do
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, i - 1, 0, {
					sign_text = "~",
					sign_hl_group = hl_prefix .. "Change",
					priority = priority,
				})
			end
		end
	end
end

local function draw_signs(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	local data = diff.calculate(bufnr)
	if not data then
		return
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	if data.type == "untracked" then
		local line_count = vim.api.nvim_buf_line_count(bufnr)
		for i = 0, line_count - 1 do
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, i, 0, {
				sign_text = "+",
				sign_hl_group = "GitDiffUntracked",
				priority = 10,
			})
		end
		return
	end

	place_marks(bufnr, data.staged, "GitDiffStaged", 9)

	place_marks(bufnr, data.unstaged, "GitDiff", 10)
end

function M.schedule_update(bufnr)
	if not debounce_timers[bufnr] then
		debounce_timers[bufnr] = vim.uv.new_timer()
	end

	local timer = debounce_timers[bufnr]
	timer:stop()

	timer:start(
		200,
		0,
		vim.schedule_wrap(function()
			draw_signs(bufnr)
		end)
	)
end

return M
