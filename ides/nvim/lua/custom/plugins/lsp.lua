return {
	'neovim/nvim-lspconfig',
	version = '*',
	config = function()
		vim.lsp.config('lua_ls', {
			settings = {
				Lua = {
					hint = { enable = true },
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { 'vim' }, -- Resolves the undefined global warning
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
					},
					telemetry = {
						enable = false,
					},
				},
			},
		})

		vim.lsp.config('yamlls', {
			settings = {
				yaml = {
					redhat = {
						telemetry = {
							enabled = false
						},
					},
				},
			},
		})
	end
}
