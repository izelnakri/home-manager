return {
  {
    "echasnovski/mini.map",
    config = function()
      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.gitsigns(),
          map.gen_integration.diagnostic(),
        },
      })
      MiniMap.open()
    end,
  },
}
