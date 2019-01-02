" Vundle config{{{
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=$HOME/.vim/bundle/Vundle.vim/
call vundle#begin('$HOME/.vim/bundle/')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

Plugin 'scrooloose/nerdtree'
Plugin 'easymotion/vim-easymotion'
Plugin 'scrooloose/nerdcommenter'
Plugin 'drewtempelmeyer/palenight.vim'
Plugin 'itchyny/lightline.vim'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

set rtp+=$HOME/.vim
"}}}
" General settings{{{
set number
set relativenumber
set showcmd
syntax on
set tabstop=4
set shiftwidth=4
set complete+=kspell
set backspace=2
let NERDTreeShowHidden=1
set foldmethod=marker
"}}}
" Key bindings{{{
nmap <leader>l :set relativenumber!<enter> :set number!<enter>
nmap <leader>t :NERDTreeToggle<enter>
nmap <leader>i :set list!<enter>

imap <leader>' ''<ESC>i
imap <leader>" ""<ESC>i
imap <leader>( ()<ESC>i
imap <leader>[ []<ESC>i
imap <leader>{ {}<ESC>i
" }}}
" Set the theme{{{
set background=dark
colorscheme palenight
set noshowmode
"}}}
" Autocommands{{{
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview 
"}}}
" Configure the status bar {{{
let g:lightline = {
	\ 'colorscheme': 'palenight',
	\ 'active': {
	\ 'left': [
	\ 	[ 'mode', 'paste' ],
	\	[ 'readonly', 'filename', 'modified' ],
	\	[ 'filetype' ]
	\ ],
	\ 'right': [
	\ 	[ 'percent', 'lineinfo'],
	\ 	[ 'fileformat' ]
	\ ],
	\ },
	\ 'inactive': {
	\ 	'right': [],
	\ },
	\ 'component_function': {
	\	'readonly': 'LightLineReadOnly',
	\	'mode': 'LightLineMode',
	\	'filetype': 'LightLineFileType',
	\	'fileformat': 'LightLineFileFormat',
	\ },
    \ }

function! LightLineMode()
	return expand('%:p') =~# '^fugitive' ? 'Fugitive' :
		\ expand('%:t') =~# '^NERD_tree' ? 'NERDTree' :
		\ lightline#mode()
endfunction

function! LightLineReadOnly()
	return &readonly && &filetype !~# '\v(help|fugitive)' && winwidth(0) >= 50 ? 'RO' : ''
endfunction

function! LightLineFileType()
	return winwidth(0) >= 75 ? &filetype : ''
endfunction

function! LightLineFileFormat()
	return winwidth(0) >= 75 ? &fileformat : ''
endfunction
" }}}
" GUI specific options{{{
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
"}}}
" Show the status line{{{
set laststatus=2
set encoding=utf-8
"}}}
