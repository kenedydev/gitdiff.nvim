local ns_id = vim.api.nvim_create_namespace("gitdiff_signs")

local M = {}

function M.setup_highlights()
	vim.api.nvim_set_hl(0, "GitDiffAdd", { fg = "#00ff00", bold = true })
	vim.api.nvim_set_hl(0, "GitDiffChange", { fg = "#0077ff", bold = true })
	vim.api.nvim_set_hl(0, "GitDiffDelete", { fg = "#ff0000", bold = true })
	vim.api.nvim_set_hl(0, "GitDiffUntracked", { fg = "#ff7700", bold = true })

	vim.api.nvim_set_hl(0, "GitDiffStagedAdd", { fg = "#007f00" })
	vim.api.nvim_set_hl(0, "GitDiffStagedChange", { fg = "#003f7f" })
	vim.api.nvim_set_hl(0, "GitDiffStagedDelete", { fg = "#7f0000" })
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

function M.render(bufnr, data, opts)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

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
				priority = opts.priority or 10,
			})
		end
		return
	end

	place_marks(bufnr, data.staged, "GitDiffStaged", (opts.priority or 10) - 1)

	place_marks(bufnr, data.unstaged, "GitDiff", opts.priority or 10)
end

return M
