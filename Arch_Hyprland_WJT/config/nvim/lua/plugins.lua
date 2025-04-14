return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    event = "VimEnter", -- Cargar Neo-tree al iniciar Neovim
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = true,
          hijack_netrw = true,
          filtered_items = {
            visible = true, -- Siempre mostrar archivos ocultos
            hide_dotfiles = false, -- No ocultar archivos que comienzan con "."
            hide_gitignored = false, -- No ocultar archivos ignorados por Git
          },
        },
      })
      -- Asegurar que Neo-tree se abre solo si no hay buffers abiertos
      vim.schedule(function()
        if vim.fn.argc() == 0 then
          vim.cmd("Neotree show left")
        end
      end)
    end
  }
}

--[[ return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        filesystem = {
          follow_current_file = true,
          hijack_netrw = true,
          filtered_items = {
            visible = true, -- Siempre mostrar archivos ocultos
            hide_dotfiles = false, -- No ocultar archivos que comienzan con "."
            hide_gitignored = false, -- No ocultar archivos ignorados por Git
          },
        },
      })
    end
  }
}

 ]]