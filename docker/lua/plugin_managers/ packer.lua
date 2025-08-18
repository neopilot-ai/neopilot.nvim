local M = {}

local function ensure_packer()
  local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end

  return false
end

function M.setup()
  local packer_bootstrap = ensure_packer()
  return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'
    if vim.env.LSP_INSTALLER == 'mason' then
      use 'williamboman/mason.nvim'
    end

    use {
      'https://github.com/neopilt-ai/neopilot.nvim.git',
      branch = vim.env.NEOPILOT_VIM_BRANCH or 'main',
      config = function()
        require('neopilot').setup({})

        if vim.env.LSP_INSTALLER == 'neopilot.vim' then
          vim.cmd.NeoPilotCodeSuggestionsInstallLanguageServer()
        end
      end,
    }

    if packer_bootstrap then
      require('packer').sync()
    end
  end)
end

return M
