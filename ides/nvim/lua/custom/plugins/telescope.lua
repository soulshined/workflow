return {
	'nvim-telescope/telescope.nvim',
	version = '*',
	dependencies = {
		'nvim-lua/plenary.nvim',
		-- optional but recommended
		{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
	},
	require('telescope').setup {
		pickers = {
			find_files = {
				follow = true,
				mappings = {
					i = {
						["<CR>"] = "select_tab",
						["<C-CR>"] = "select_vertical",
					},
					n = {
						["<CR>"] = "select_tab",
						["<C-CR>"] = "select_vertical",
					},
				}
			}
		},
	},
	config = function()
		vim.api.nvim_set_keymap('n', '<Leader>ff', '<cmd>Telescope find_files<CR>', { desc = "Fuzzy find files in cwd" })
		-- vim.api.nvim_set_keymap('n', '<Leader>fg', '<cmd>Telescope live_grep<CR>', { desc = "Fuzzy find recent files" })
		-- vim.api.nvim_set_keymap('n', '<Leader>fb', '<cmd>Telescope buffers<CR>', { desc = "Find string in cwd" })
	end,
}
