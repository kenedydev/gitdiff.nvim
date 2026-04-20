local M = {}

M.options = {
	enabled = true,
	signs = {
		enabled = true,
		priority = 10,
	},
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

return M
