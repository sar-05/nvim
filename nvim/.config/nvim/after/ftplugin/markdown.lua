vim.bo.shiftwidth = 2
vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.opt_local.spelllang = { "en_us", "es_mx" }

local group = vim.api.nvim_create_augroup("markdown-winlocal", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function()
		if vim.bo.filetype == "markdown" then
			vim.wo.colorcolumn = "80"
			vim.wo.spell = true
		end
	end,
})

vim.api.nvim_create_autocmd("BufLeave", {
	group = group,
	callback = function()
		if vim.bo.filetype == "markdown" then
			vim.wo.colorcolumn = ""
			vim.wo.spell = false
		end
	end,
})
