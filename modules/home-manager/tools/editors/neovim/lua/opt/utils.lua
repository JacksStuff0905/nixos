-- Command used for checking lsp, linter and formatter name mappings, aka lua-language-server -> lua_ls
vim.api.nvim_create_user_command("TOOLMasonToolMap", function()
  local mason_registry = require("mason-registry")
  local mappings = {}

  -- Add LSP mappings if mason-lspconfig is available
  local ok, mason_lspconfig = pcall(require, "mason-lspconfig")
  if ok then
    local lsp_map = mason_lspconfig.get_mappings().package_to_lspconfig
    for pkg, lsp in pairs(lsp_map) do
      table.insert(mappings, {
        display = pkg .. " → " .. lsp .. " (LSP)",
        name = pkg,
        type = "LSP",
      })
    end
  end

  -- Add all other Mason tools
  for _, pkg in ipairs(mason_registry.get_installed_packages()) do
    local cat = pkg.spec.categories[1]
    if cat ~= "LSP" then
      table.insert(mappings, {
        display = pkg.name .. " (" .. cat .. ")",
        name = pkg.name,
        type = cat,
      })
    end
  end

  -- Sort by name
  table.sort(mappings, function(a, b) return a.name < b.name end)

  -- Show via vim.ui.select
  vim.ui.select(mappings, {
    prompt = "Installed Mason Tools",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      vim.notify(choice.name .. " is a " .. choice.type)
    end
  end)
end, {})

