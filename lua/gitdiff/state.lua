local M = {
	cache = {},
	_jobs = {},
}

function M.update(bufnr)
	if M._jobs[bufnr] == "running" then
		M._jobs[bufnr] = "queued"
		return
	end

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return
	end

	M._jobs[bufnr] = "running"

	vim.system({ "git", "status", "--porcelain", "--", filepath }, { text = true }, function(status_obj)
		if not vim.api.nvim_buf_is_valid(bufnr) then
			M._jobs[bufnr] = nil
			return
		end

		local is_untracked = status_obj.stdout and status_obj.stdout:match("^%?%?")

		if is_untracked then
			M.cache[bufnr] = { is_untracked = true }
			M.check_queue(bufnr)
			return
		end

		vim.system({ "git", "show", ":" .. filepath }, { text = true }, function(idx_obj)
			if not vim.api.nvim_buf_is_valid(bufnr) then
				M._jobs[bufnr] = nil
				return
			end

			local index_text = idx_obj.code == 0 and idx_obj.stdout or ""

			vim.system({ "git", "show", "HEAD:" .. filepath }, { text = true }, function(head_obj)
				if not vim.api.nvim_buf_is_valid(bufnr) then
					M._jobs[bufnr] = nil
					return
				end

				local head_text = head_obj.code == 0 and head_obj.stdout or ""

				M.cache[bufnr] = {
					is_untracked = false,
					index_text = index_text,
					head_text = head_text,
				}

				M.check_queue(bufnr)
			end)
		end)
	end)
end

function M.check_queue(bufnr)
	if M._jobs[bufnr] == "queued" then
		M._jobs[bufnr] = nil
		M.update(bufnr)
	else
		M._jobs[bufnr] = nil
		vim.schedule(function()
			require("gitdiff.ui").schedule_update(bufnr)
		end)
	end
end

function M.get(bufnr)
	return M.cache[bufnr]
end

function M.clear(bufnr)
	M.cache[bufnr] = nil
	M._jobs[bufnr] = nil
end

return M
