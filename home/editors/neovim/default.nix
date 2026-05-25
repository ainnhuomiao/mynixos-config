{ pkgs, ... }:
let
  lazyvim-init = ''
    -- bootstrap lazy.nvim, LazyVim and your plugins
    require("config.lazy")
  '';

  lazyvim-lazy = ''
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not (vim.uv or vim.loop).fs_stat(lazypath) then
      local repo = "https://github.com/folke/lazy.nvim.git"
      vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    require("lazy").setup({
      spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        { import = "plugins" },
      },
      defaults = {
        lazy = true,
        version = "*",
      },
      install = { colorscheme = { "tokyonight", "catppuccin" } },
      checker = { enabled = true },
    })
  '';

  lazyvim-options = ''
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    vim.opt.clipboard = "unnamedplus"
    vim.opt.mouse = "a"
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.cursorline = true
    vim.opt.expandtab = true
    vim.opt.shiftwidth = 2
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.smartindent = true
    vim.opt.wrap = false
    vim.opt.swapfile = false
    vim.opt.backup = false
    vim.opt.undofile = true
    vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
    vim.opt.hlsearch = false
    vim.opt.incsearch = true
    vim.opt.termguicolors = true
    vim.opt.scrolloff = 8
    vim.opt.signcolumn = "yes"
    vim.opt.updatetime = 50
    vim.opt.timeoutlen = 300
    vim.opt.splitright = true
    vim.opt.splitbelow = true
    vim.opt.inccommand = "split"

    vim.filetype.add({
      pattern = {
        [".*nix/.*%.nix"] = "nix",
      },
    })
  '';

  lazyvim-keymaps = ''
    vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

    -- move lines
    vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
    vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

    -- keep cursor centered
    vim.keymap.set("n", "<C-d>", "<C-d>zz")
    vim.keymap.set("n", "<C-u>", "<C-u>zz")
    vim.keymap.set("n", "n", "nzzzv")
    vim.keymap.set("n", "N", "Nzzzv")

    -- better paste
    vim.keymap.set("x", "<leader>p", '"_dP')
  '';

  nix-plugin = ''
    return {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "catppuccin",
      },
    }
  '';

  colorscheme-plugin = ''
    return {
      { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    }
  '';
in
{
  home.packages = with pkgs; [
    neovim
    ripgrep
    fd
    lazygit
  ];

  xdg.configFile = {
    "nvim/init.lua".text = lazyvim-init;
    "nvim/lua/config/lazy.lua".text = lazyvim-lazy;
    "nvim/lua/config/options.lua".text = lazyvim-options;
    "nvim/lua/config/keymaps.lua".text = lazyvim-keymaps;
    "nvim/lua/plugins/colorscheme.lua".text = colorscheme-plugin;
    "nvim/lua/plugins/nix.lua".text = nix-plugin;
  };

  programs.fish.shellAliases = {
    e = "nvim";
    vi = "nvim";
    vim = "nvim";
  };
  programs.bash.shellAliases = {
    e = "nvim";
    vi = "nvim";
    vim = "nvim";
  };
}
