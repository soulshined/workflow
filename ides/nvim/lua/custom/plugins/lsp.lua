return {
	'neovim/nvim-lspconfig',
	version = '*',
	config = function()
		local lspconfig = require('lspconfig')

		lspconfig.lua_ls.setup({
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
		lspconfig.gopls.setup({})
		lspconfig.jsonls.setup{}
		lspconfig.pylsp.setup{}
		lspconfig.clangd.setup{}
		lspconfig.yamlls.setup({
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
