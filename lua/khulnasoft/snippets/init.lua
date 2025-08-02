-- lua/khulnasoft/snippets/init.lua

-- Try to require dependencies safely
local ok_luasnip, ls = pcall(require, "luasnip")
if not ok_luasnip then
  vim.notify("LuaSnip not found!", vim.log.levels.ERROR)
  return
end

local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node

-- Load VSCode-style snippets lazily
local ok_loader, loader = pcall(require, "luasnip.loaders.from_vscode")
if ok_loader then
  loader.lazy_load()
end

-- Helper: Treesitter condition for snippet expansion
local function in_lua_chunk()
  local ok_ts, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  if not ok_ts then
    return false
  end
  local node = ts_utils.get_node_at_cursor()
  return node and node:type() == "chunk"
end

-- Register Lua snippets
ls.add_snippets("lua", {
  -- Function definition snippet
  s({
    trig = "fn",
    name = "Lua function",
    dscr = "Expands to a Lua function definition",
    condition = in_lua_chunk,
  }, {
    t("function "), i(1, "name"), t("()"),
    t({ "", "  " }), i(0),
    t({ "", "end" }),
  }),
})
