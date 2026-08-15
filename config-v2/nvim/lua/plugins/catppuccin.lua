return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      color_overrides = {
        mocha = {
          base = "#1e1e1e",
          mantle = "#1e1e1e",
        },
      },
      flavour = "mocha",
      integrations = {
        mason = true,
        neotree = true,
        cmp = true,
      },
    })

    vim.cmd.colorscheme "catppuccin"
  end
}
