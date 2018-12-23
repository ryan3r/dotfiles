" Begin vundle config
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=$HOME/.vim/bundle/Vundle.vim/
call vundle#begin('$HOME/.vim/bundle/')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'tpope/vim-fugitive'
Plugin 'scrooloose/nerdtree'
Plugin 'easymotion/vim-easymotion'
Plugin 'scrooloose/nerdcommenter'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

set rtp+=$HOME/.vim

set number
set relativenumber
set showcmd
syntax on
set tabstop=4
set shiftwidth=4
set complete+=kspell
set backspace=2

nmap <leader>l :set relativenumber!<enter> :set number!<enter>
nmap <leader>t :NERDTreeToggle<enter>
nmap <leader>i :set list!<enter>

imap <leader>' ''<ESC>i
imap <leader>" ""<ESC>i
imap <leader>( ()<ESC>i
imap <leader>[ []<ESC>i
imap <leader>{ {}<ESC>i

colorscheme ryan

if has("gui_running")
    set cursorline
    set guifont=Source_Code_Pro_for_Powerline:h12:cANSI:qDRAFT

    set lines=35
    set columns=100

    set guioptions-=m
    set guioptions-=T
    set guioptions-=L
    set guioptions-=r
endif

" Show the status line
set laststatus=2
set encoding=utf-8
