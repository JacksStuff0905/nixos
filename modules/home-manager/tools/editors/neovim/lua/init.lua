local debug = false


-- Load optional module
local function require_opt(module)
  local success = pcall(require, module)
  if (not success) and debug then
    print("Failed to load optional module" .. module)
  end
end

-- termguicolors
vim.o.termguicolors = true


-- Load required configs
-- require("req.lazy")

-- Load editor configs
require("conf.format")
require("conf.tools")
require("conf.keymap")
require("conf.theme")
require("conf.clipboard")

-- Load optional configs
require_opt("opt.utils")
require_opt("opt.spellcheck")
