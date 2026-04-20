local M = {
	cache = {},
	_jobs = {},
}

function M.update(bufnr, on_done)
	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if buftype ~= "" then
		return
	end

	if M._jobs[bufnr] == "running" then
		M._jobs[bufnr] = "queued"
		return
	end

	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return
	end

	M._jobs[bufnr] = "running"

	local filedir = vim.fn.fnamemodify(filepath, ":h")
	local filename = vim.fn.fnamemodify(filepath, ":t")

	local results = {
		status = "",
		index = "",
		head = "",
		completed = 0,
	}

	local function check_done()
		results.completed = results.completed + 1

		if results.completed == 3 then
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_name(bufnr) ~= filepath then
					M._jobs[bufnr] = nil
					return
				end

				M.cache[bufnr] = {
					is_untracked = results.status:match("^%?%?") ~= nil,
					index_text = results.index,
					head_text = results.head,
				}

				local current_job_status = M._jobs[bufnr]
				M._jobs[bufnr] = nil

				if current_job_status == "queued" then
					M.update(bufnr, on_done)
				elseif on_done then
					on_done(M.cache[bufnr])
				end
			end)
		end
	end

	vim.system({ "git", "status", "--porcelain", "--", filename }, { cwd = filedir }, function(obj)
		results.status = obj.code == 0 and obj.stdout or ""
		check_done()
	end)

	vim.system({ "git", "show", ":./" .. filename }, { cwd = filedir }, function(obj)
		results.index = obj.code == 0 and obj.stdout or ""
		check_done()
	end)

	vim.system({ "git", "show", "HEAD:./" .. filename }, { cwd = filedir }, function(obj)
		results.head = obj.code == 0 and obj.stdout or ""
		check_done()
	end)
end

function M.get(bufnr)
	return M.cache[bufnr]
end

function M.clear(bufnr)
	M.cache[bufnr] = nil
	M._jobs[bufnr] = nil
end

return M
