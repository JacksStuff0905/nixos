-- The main lua config, used no matter which profile is selected

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

-- Leader mappings
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load editor configs
require("req.format")
require("req.tools")
require("req.keymap")
require("req.theme")
require("req.clipboard")
