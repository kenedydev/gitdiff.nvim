local M = {}

function M.get_hunks_data(git_data, buffer_lines)
	if git_data.is_untracked then
		return { type = "untracked" }
	end

	local current_text = table.concat(buffer_lines, "\n") .. "\n"

	local diff_opts = { result_type = "indices", algorithm = "histogram", indent_heuristic = true }

	local staged_data = vim.text.diff(git_data.head_text, git_data.index_text, diff_opts)

	local unstaged_data = vim.text.diff(git_data.index_text, current_text, diff_opts)

	return {
		type = "tracked",
		staged = type(staged_data) == "table" and staged_data or {},
		unstaged = type(unstaged_data) == "table" and unstaged_data or {},
	}
end

return M
