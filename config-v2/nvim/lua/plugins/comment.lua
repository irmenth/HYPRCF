return {
  -- gcc for comment ; gbc for block
  {
    "numToStr/Comment.nvim",
    lazy = false,
    config = function()
      require('Comment').setup()
    end
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = false,
    event = { "User FileOpened" },
    config = function()
      vim.opt.updatetime = 100
    end
  }
}
