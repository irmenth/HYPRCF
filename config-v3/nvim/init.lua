-- 显示行号
vim.opt.number = true          -- 显示当前行号
vim.opt.relativenumber = true  -- 开启相对行号

-- 彻底禁用背景颜色渲染，直接使用终端颜色
-- 这行代码会强制让 Neovim 的 Normal 高亮组不带背景色
vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
vim.cmd("highlight LineNr guibg=NONE ctermbg=NONE")
vim.cmd("highlight SignColumn guibg=NONE ctermbg=NONE")

-- 启用真彩色支持（确保能正确识别 NONE）
vim.opt.termguicolors = true

-- 开启当前行高亮
vim.opt.cursorline = true

vim.opt.clipboard = "unnamedplus"

