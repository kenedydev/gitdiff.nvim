local M = { _jobs = {} }

function M.fetch(bufnr, on_done)
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

	local function finish_job(data)
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_name(bufnr) ~= filepath then
				M._jobs[bufnr] = nil
				return
			end

			local last_status = M._jobs[bufnr]
			M._jobs[bufnr] = nil

			if last_status == "queued" then
				M.fetch(bufnr, on_done)
			else
				on_done(data)
			end
		end)
	end

	vim.system({ "git", "status", "--porcelain", "--", filename }, { cwd = filedir, text = true }, function(obj)
		if obj.code ~= 0 then
			finish_job(nil)
			return
		end

		local status = obj.stdout or ""

		if status:match("^%?%?") ~= nil then
			finish_job({ is_untracked = true, index_text = "", head_text = "" })
			return
		end

		local git_data = {
			is_untracked = false,
			index_text = "",
			head_text = "",
		}

		local completed = 0
		local function check_shows_done()
			completed = completed + 1
			if completed == 2 then
				finish_job(git_data)
			end
		end

		vim.system({ "git", "show", ":./" .. filename }, { cwd = filedir, text = true }, function(show_idx)
			git_data.index_text = show_idx.code == 0 and show_idx.stdout or ""
			check_shows_done()
		end)

		vim.system({ "git", "show", "HEAD:./" .. filename }, { cwd = filedir, text = true }, function(show_head)
			git_data.head_text = show_head.code == 0 and show_head.stdout or ""
			check_shows_done()
		end)
	end)
end

return M
