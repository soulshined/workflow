vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.smartindent = true
vim.opt.autoindent = true
vim.opt.scrolloff = 10
vim.opt.signcolumn = 'yes'
vim.opt.wrap = false
vim.opt.colorcolumn = '100'
vim.opt.mouse = 'a'
vim.opt.list = true
vim.opt.listchars = { tab = '→ ', trail = '•', nbsp = '␣', eol = '', precedes = '«', extends = '«' }
-- decrease update time
vim.updatetime = 250
-- decrease map sequence wait time
vim.opt.timeoutlen = 300
vim.opt.completeopt = 'menu,menuone,preview,popup,noinsert,fuzzy'
vim.opt.winborder = 'double'
vim.g.netrw_preview = 1
vim.g.netrw_liststyle = 3
vim.g.netrw_alto = 0

if not vim.fn.has('win32') then
	vim.schedule(function()
		vim.opt.clipboard = 'unnamedplus'
	end)
end

require('config.autocmds')
require('config.keymaps')
require('config.vt')
require('custom.lazy')

vim.lsp.inlay_hint.enable()
vim.lsp.enable({ 'lua_ls' })
vim.diagnostic.config({ virtual_lines = true, signs = false })
