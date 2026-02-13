-- for now this is acting as 'refactor symbol' -- needs better solution
vim.api.nvim_set_keymap('n', '<F2>', '*:%s///g<left><left>', { noremap = true })

vim.api.nvim_set_keymap('n', '<M-Up>', ':move .-2<CR>', { desc = 'Move line up', noremap = true })
vim.api.nvim_set_keymap('n', '<M-Down>', ':move .1<CR>', { desc = 'Move line down', noremap = true })
vim.api.nvim_set_keymap('i', '<M-Up>', ":'<,'>move .-2<CR>", { desc = 'Move line up', noremap = true })
vim.api.nvim_set_keymap('i', '<M-Down>', ":'<,'>move .1<CR>", { desc = 'Move line down', noremap = true })
vim.api.nvim_set_keymap('v', '<M-Up>', ":'<,'>move .-2<CR>", { desc = 'Move line up', noremap = true })
vim.api.nvim_set_keymap('v', '<M-Down>', ":'<,'>move .1<CR>", { desc = 'Move line down', noremap = true })

vim.api.nvim_set_keymap('n', '<M-S-Up>', ':t -1<CR>', { desc = 'Duplicate line up', noremap = true })
vim.api.nvim_set_keymap('n', '<M-S-Down>', ':t.<CR>', { desc = 'Duplicate line down', noremap = true })
-- this doesn't work as good as normal mode, i don't like how the cursor moves to the left each time
vim.api.nvim_set_keymap('i', '<M-S-Up>', '<Esc>:t -1<CR>i', { desc = 'Duplicate line up', noremap = true })
vim.api.nvim_set_keymap('i', '<M-S-Down>', '<Esc>:t.<CR>i', { desc = 'Duplicate line up', noremap = true })
vim.api.nvim_set_keymap('i', '<C-Del>', '<C-o>dw', { desc = 'Delete Word Forward ' })
vim.api.nvim_set_keymap('n', '<Home>', '^', { desc = 'Delete Word Forward ' })
vim.api.nvim_set_keymap('n', '<End>', 'g_', { desc = 'Delete Word Forward ' })
vim.api.nvim_set_keymap('i', '<Home>', '<C-o>^', { desc = 'Delete Word Forward ' })
vim.api.nvim_set_keymap('i', '<End>', '<Esc>A', { desc = 'Delete Word Forward ' })

vim.keymap.set('n', '<C-S-e>', function()
	vim.cmd([[Explore]])
	vim.cmd([[call feedkeys("/")]])
end, { desc = 'Open netrw explorer' })

--#region search
vim.api.nvim_set_keymap('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Remove highlighted search term when exiting' })
--#endregion search

--#region document
vim.keymap.set('n', '<M-S-f>', function()
	vim.lsp.buf.format()
end, { desc = 'Format Document' })
--#endregion document

-- this prevents you from using normal keymaps - want that for windows
vim.keymap.set('n', '<C-`>', function()
	vim.api.nvim_open_win(0, true, { height = 10, split = 'below' })
	vim.cmd([[terminal]])
	vim.cmd([[startinsert]])
end, { desc = 'Open terminal in bottom of window' })
