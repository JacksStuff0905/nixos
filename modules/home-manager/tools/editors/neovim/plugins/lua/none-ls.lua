return {
  {
    "nvimtools/none-ls.nvim",
    config = function ()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          -- Lua
          null_ls.builtins.formatting.stylua,

          -- C/C++
          null_ls.builtins.formatting.clang_format,
          -- null_ls.builtins.diagnostics.cpplint,

          -- Docker
          null_ls.builtins.diagnostics.hadolint,

          -- Python
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.isort,

          -- GDscript
          null_ls.builtins.diagnostics.gdlint,
          null_ls.builtins.formatting.gdformat,

        }
      })
    end
  }
}
