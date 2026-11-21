-- Options
vim.opt.number = true             -- Line Numbers
vim.opt.clipboard = "unnamedplus" -- Buffer -> Windows Clipboard
vim.opt.signcolumn = "yes"        -- Reserve Error Indicator Space

vim.opt.completeopt = { "menuone", "noselect", "popup" } -- Completion Menu

-- Tab Options
vim.opt.expandtab = true          -- Tab Character -> Spaces
vim.opt.tabstop = 2               -- Tab Characters as 2 Spaces
vim.opt.shiftwidth = 2            -- ">>" and "<<": 2 Spaces
vim.opt.softtabstop = 2           -- Tab, Backspace: 2 Spaces

-- Plugins
vim.g.vimtex_view_general_viewer = vim.fn.expand("~/AppData/Local/SumatraPDF/SumatraPDF.exe")
vim.g.vimtex_view_general_options = "-reuse-instance -forward-search @tex @line @pdf"

-- Install/Load Plugins !!!
vim.pack.add({
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/lervag/vimtex",
  "https://github.com/stevearc/oil.nvim",
})

require("oil").setup({ view_options = { show_hidden = true } })
vim.keymap.set("n", "-", "<cmd>Oil<cr>")

require("nvim-treesitter").install({ "rust", "python", "haskell" })

-- LSP
vim.lsp.config("rust_analyzer", {
  settings = { ["rust-analyzer"] = { check = { command = "clippy" } } },
})
vim.lsp.config("texlab", {
  settings = { texlab = { chktex = { onOpenAndSave = true, onEdit = true } } },
})
vim.lsp.enable({ "rust_analyzer", "pyright", "ruff", "hls", "texlab" })

vim.diagnostic.config({
  virtual_text = true,
  update_in_insert = true,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Autocommands
local group = vim.api.nvim_create_augroup("MyConfig", { clear = true })

-- Leptos Formatter Function
local function leptosfmt(buf)
  -- Verify file is Leptos
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  if not text:find("view!", 1, true) then return end
  -- Run leptosfmt
  local res = vim.system({ "leptosfmt", "--stdin", "--quiet" }, { stdin = text .. "\n" }):wait()
  if res.code ~= 0 or not res.stdout or res.stdout == "" then
    vim.notify("leptosfmt: " .. (res.stderr or "failed"), vim.log.levels.WARN)
    return
  end
  -- Tidy output
  local stdout = res.stdout:gsub("\r\n", "\n"):gsub("\n$", "")
  local out = vim.split(stdout, "\n", { plain = true })
  if vim.deep_equal(out, lines) then return end
  -- Put result back into buffer
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.fn.winrestview(view)
end

-- Completion
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end
  end,
})

-- Cursor Memory
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})

-- Format First
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  pattern = { "*.rs", "*.py", "*.hs", "*.tex" },
  callback = function(args)
    vim.lsp.buf.format({ timeout_ms = 5000 })
    if vim.bo[args.buf].filetype == "rust" then leptosfmt(args.buf) end
  end,
})

-- Treesitter
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "rust", "python", "haskell" },
  callback = function(args)
    vim.treesitter.start()
    if vim.bo[args.buf].filetype == "python" then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Compile LaTeX on opening .tex file
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "VimtexEventInitPost",
  callback = function() vim.cmd("VimtexCompile!") end,
})

-- Terminal
vim.api.nvim_create_user_command("PS", function()
  vim.cmd("topleft 60vsplit | terminal pwsh")
  vim.cmd("startinsert") -- Insert Mode Automatically
end, {})

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")       -- ESC:   Terminal Normal Mode
vim.keymap.set("t", "<A-l>", "<C-\\><C-n><C-w>l") -- Alt+l: Terminal -> Code
vim.keymap.set("n", "<A-h>", "<C-w>h")            -- Alt+h: Code -> Terminal
vim.api.nvim_create_autocmd("BufEnter", {
  group = group,
  pattern = "term://*",
  command = "startinsert",
})
