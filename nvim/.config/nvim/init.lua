vim.o.number = true
vim.o.relativenumber = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.confirm = true
vim.o.undofile = true
vim.o.cursorline = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.signcolumn = "yes"
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.o.breakindent = true
vim.o.splitkeep = "screen"
vim.o.wrap = false
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.laststatus = 3
vim.g.netrw_altfile = 1

-- Disable optional providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- unify nvim and system clipboard
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Save buffer view
vim.api.nvim_create_autocmd("BufWinLeave", {
	desc = "Save view when leaving a buffer",
	callback = function(ev)
		local buf = ev.buf
		if
			--[[Check for appropiate buffers:
      valid buffer: the buffer is in the buffer list
      non-empty name: the buffer name isn't an empty string
      empty type: only non-modifiable buffers like help buffers have types ]]
			--
			vim.api.nvim_buf_is_valid(buf)
			and vim.api.nvim_buf_get_name(buf) ~= ""
			and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
		then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("silent! mkview")
			end)
		end
	end,
})

-- Do not restore curdir when using mkload, as this conflicts with fzf-lua.
vim.opt.viewoptions:remove("curdir")

-- Load view if it exit for the buffer
vim.api.nvim_create_autocmd("BufWinEnter", {
	desc = "Load view when entering a buffer",
	callback = function(ev)
		local buf = ev.buf
		if
			vim.api.nvim_buf_is_valid(buf)
			and vim.api.nvim_buf_get_name(buf) ~= ""
			and vim.api.nvim_get_option_value("buftype", { buf = buf }) == ""
		then
			vim.api.nvim_buf_call(buf, function()
				vim.cmd("silent! loadview")
			end)
		end
	end,
})

if vim.fn.executable("git") == 1 then
	vim.pack.add({
		{ src = "https://github.com/vague-theme/vague.nvim" },
	})
else
	vim.notify("Unable to install plugins, no git binary found", vim.log.levels.WARN)
end

-- set colorscheme
local colorscheme_status, err = pcall(vim.cmd.colorscheme, "vague")
if not colorscheme_status then
	vim.notify("Unable to set colorscheme: " .. err, vim.log.levels.ERROR)
end
