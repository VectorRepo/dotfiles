-- ================================================================================================
-- TITLE : mini.pairs  (nvim-autopairs csere)
-- mini.nvim már úgyis betöltődik → nincs extra plugin overhead
-- blink.cmp-vel natívan működik, nem kell külön "confirm_done" integráció
-- ================================================================================================

return {
  "echasnovski/mini.pairs",
  version = false,
  event = "InsertEnter",
  opts = {
    -- Alapértelmezett párok: (), [], {}, '', "", ``
    -- Treesitter-aware: nem zár párat kommentben/stringben ahol nem kell
    modes = { insert = true, command = false, terminal = false },
  },
}
