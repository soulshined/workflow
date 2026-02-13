Statusline = {}

function Statusline.get()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local byte_num = vim.fn.line2byte(cursor[1]) + cursor[2] - 1
	return table.concat {
		"%<%f ",
		"%h%w%m%r%q%k%=%-14.(%l:%c%V[",
		tostring(byte_num),
		"] %b,x%B%) %P"
	}
end

local group = vim.api.nvim_create_augroup("freer.Statusline", { clear = true })

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
	group = group,
	desc = 'Activate statusline on focus',
	callback = function()
		vim.opt.statusline = "%!v:lua.Statusline.get()"
	end,
})
