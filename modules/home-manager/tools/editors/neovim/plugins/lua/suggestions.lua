return {
  {
    "meeehdi-dev/bropilot.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "j-hui/fidget.nvim",
    },
    opts = {
      auto_suggest = false,
      model = "starcoder2:3b",
      debounce = 500,
      keymap = {
        accept_line = "<leader>ac",
      },
    },
    config = function(_, opts)
      -- require("bropilot").setup(opts)
    end,
  },
}
