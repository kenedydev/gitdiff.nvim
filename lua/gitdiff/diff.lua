local M = {}

function M.calculate(git_state, current_lines)
	if not git_state then
		return nil
	end

	if git_state.is_untracked then
		return { type = "untracked" }
	end

	local current_text = table.concat(current_lines, "\n") .. "\n"

	local diff_opts = {
		result_type = "indices",
		algorithm = "histogram",
		indent_heuristic = true,
	}

	local staged_data = vim.text.diff(git_state.head_text, git_state.index_text, diff_opts)

	local unstaged_data = vim.text.diff(git_state.index_text, current_text, diff_opts)

	return {
		type = "tracked",
		staged = type(staged_data) == "table" and staged_data or {},
		unstaged = type(unstaged_data) == "table" and unstaged_data or {},
	}
end

return M
