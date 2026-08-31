vim.opt_local.spelllang = { "en_us" }

local group = vim.api.nvim_create_augroup("gitcommit-winlocal", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
	group = group,
	callback = function()
		if vim.bo.filetype == "gitcommit" then
			vim.wo.spell = true
		end
	end,
})

vim.api.nvim_create_autocmd("BufLeave", {
	group = group,
	callback = function()
		if vim.bo.filetype == "gitcommit" then
			vim.wo.spell = false
		end
	end,
})
