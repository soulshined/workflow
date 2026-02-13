vim.api.nvim_create_autocmd('VimEnter', {
	-- Change directory to directory of file that was first opened.
	-- However change it for tabs
	group = vim.api.nvim_create_augroup('freer.ChangeDirectory', { clear = true }),
	callback = function()
		vim.cmd('tcd ' .. vim.fn.expand('%:p:h'))
	end
})

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('freer.lsp', {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
		end
	end,
})

-- remove trailing whitespace before save
vim.api.nvim_create_autocmd('BufWritePre', {
	callback = function()
		-- Save cursor position to restore later
		local curpos = vim.api.nvim_win_get_cursor(0)
		-- Search and replace trailing whitespaces
		vim.cmd([[keeppatterns %s/\s\+$//e]])
		vim.api.nvim_win_set_cursor(0, curpos)
	end,
})
