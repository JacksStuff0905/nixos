-- Configure lsp vim.keymap.set("n", "<leader>dc", vim.lsp.buf.hover, {}) vim.keymap.set("n", "<leader>df", vim.lsp.buf.definition, {}) vim.keymap.set("n", "<leader>us", vim.lsp.buf.references, {})
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})

-- Configure formatters
vim.keymap.set("n", "<leader>fr", vim.lsp.buf.format, {})

-- Configure linters
vim.keymap.set("n", "<leader>er", vim.diagnostic.open_float, {})


-- Configure debuggers
--[[ local dap = require("dap")
vim.keymap.set("n", "<leader>br", dap.toggle_breakpoint, {})
vim.keymap.set("n", "<leader>cn", dap.continue, {})
]]--

-- Configure window navigation
vim.keymap.set("n", "H", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "J", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "K", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "L", "<C-w>l", { desc = "Move to right window" })

vim.keymap.set("n", "<leader>bc", "<C-o>", { desc = "Return to previous window" })
vim.keymap.set("n", "<leader>fw", "<C-i>", { desc = "Return to next window" })

-- Configure highlighting
vim.keymap.set("n", "<leader>nh", ":noh<CR>", { desc = "Hide highlight" })


-- Configure git
local gitsigns = require("gitsigns")
vim.keymap.set("n", "<leader>sh", gitsigns.stage_hunk, { desc = "Stage hunk" })
vim.keymap.set("n", "<leader>sb", gitsigns.stage_buffer, { desc = "Stage buffer" })

vim.keymap.set("n", "<leader>rh", gitsigns.reset_hunk, { desc = "Reset hunk" })
vim.keymap.set("n", "<leader>rb", gitsigns.reset_buffer, { desc = "Reset buffer" })

vim.keymap.set("n", "<leader>td", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })
