# burvy's nvim config
Hi, welcome to my NeoVim config. I do a lot of Rust, Haskell, Python (for college), 
and LaTeX, so I have those set up. Leptos is also set up, as well as a few nifty 
tools:

```lua
-- Terminal: Use `Dev` to launch Powershell on the side
vim.api.nvim_create_user_command("Dev", function()
  vim.cmd("topleft 60vsplit | terminal pwsh")
  vim.cmd("startinsert") -- Insert Mode Automatically
end, {})

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")       -- ESC:   Terminal Normal Mode
vim.keymap.set("t", "<A-l>", "<C-\\><C-n><C-w>l") -- Alt+l: Terminal -> Code
vim.keymap.set("n", "<A-h>", "<C-w>h")            -- Alt+h: Code -> Terminal
```
I also added `wgsl`, to use it, you need to install it:  
`cargo install --git https://github.com/wgsl-analyzer/wgsl-analyzer wgsl-analyzer`
