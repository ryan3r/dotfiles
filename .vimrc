set nocompatible

" Plug config{{{
call plug#begin('$HOME/.vim/plugged/')

Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/nerdcommenter'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'itchyny/lightline.vim'
Plug 'fatih/vim-go'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-commentary'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'sgur/vim-editorconfig'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'
Plug 'tmux-plugins/vim-tmux'
Plug 'tmux-plugins/vim-tmux-focus-events'
Plug 'roxma/vim-tmux-clipboard'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

if v:version >= 703
	let g:signify_realtime=1
	Plug 'mhinz/vim-signify'
endif

call plug#end()

" Open plug in a new window
let g:plug_window = '-tabnew'
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
set foldmethod=syntax
set laststatus=2
set wildignore=*.o,*.pyc,*.class,*.jar,*.exe,*.a,*.dll,*.so,*/node_modules/*,*.swp
set conceallevel=2

let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_show_hidden = 1
"}}}
" Key bindings{{{
nmap <leader>l :set relativenumber!<enter> :set number!<enter>
nmap <leader>t :NERDTreeToggle<enter>
nmap <leader>i :set list!<enter>
nmap <leader>p :CtrlPBuffer<enter>
nmap <leader>r :source .vimrc<enter> :echo "Config reloaded"<enter>

" Switch vim windows
nmap <C-j> <C-W>j
nmap <C-k> <C-W>k
nmap <C-l> <C-W>l
nmap <C-h> <C-W>h

" Switch buffer easliy
nmap <Tab> :bnext<enter>
nmap <S-Tab> :bprev<enter>
" }}}
" Set the theme{{{
set background=dark
set noshowmode

if !empty(globpath(&rtp, 'colors/palenight.vim'))
	colorscheme palenight
endif
"}}}
" Autocommands{{{
autocmd FileType vim setlocal foldmethod=marker
autocmd FileType sh setlocal foldmethod=marker
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
	\	[ 'lineinfo' ],
	\ 	[ 'percent' ], 
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
