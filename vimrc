set nocompatible

" Plug config{{{
call plug#begin('$HOME/.vim/plugged/')

Plug 'scrooloose/nerdtree'
Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/nerdcommenter'
Plug 'drewtempelmeyer/palenight.vim'
Plug 'itchyny/lightline.vim'
" Plug 'fatih/vim-go'
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
Plug 'w0rp/ale'
Plug 'maximbaz/lightline-ale'
Plug 'pangloss/vim-javascript'
Plug 'tpope/vim-dispatch'
" Plug 'zivyangll/git-blame.vim'
Plug 'rust-lang/rust.vim'
Plug 'cmcaine/vim-uci'

" if v:version >= 703
	" let g:signify_realtime=1
	" Plug 'mhinz/vim-signify'
" endif

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
set foldlevel=1000
set laststatus=2
set wildignore=*.o,*.pyc,*.class,*.jar,*.exe,*.a,*.dll,*.so,*/node_modules/*,*.swp,*.docx
set conceallevel=2
set nomodeline
set complete+=.,w,b,t,i,u,kspell
set ttymouse=xterm2
set mouse=a
" Warn when we pass 80 chars
set colorcolumn=81

let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_show_hidden = 1
"}}}
" Key bindings{{{
nmap <silent><leader>l :set relativenumber!<enter> :set number!<enter>
nmap <silent><leader>t :NERDTreeToggle<enter>
nmap <silent><leader>i :set list!<enter>
nmap <silent><leader>p :CtrlPBuffer<enter>
nmap <silent><leader>r :source ~/.vimrc<enter> :echo "Config reloaded"<enter>
nmap <silent><leader>c :noh<enter>
nmap <silent><leader>s :set spell!<enter>
nmap <silent><leader>e :lopen<enter>
nmap <silent><leader>q :lclose<enter>
nmap <silent><leader>n :set relativenumber!<enter>
nmap <silent><leader>o 0dW

" Switch vim windows
" map <C-j> <Esc><C-W>j
" map <C-k> <Esc><C-W>k
" map <C-l> <Esc><C-W>l
" map <C-h> <Esc><C-W>h

" Switch buffer easily
nmap <silent><Tab> :bnext<enter>
nmap <silent><S-Tab> :bprev<enter>

" Flip through the location and quickfix lists
nmap <silent>]l :lnext<enter>
nmap <silent>[l :lprev<enter>
nmap <silent>]c :cnext<enter>
nmap <silent>[c :cprev<enter>
" }}}
" Commands {{{
command! Todo :vimgrep /TODO: @rray/ **/*.*<enter>
" }}}
" Set the theme{{{
set background=dark
set noshowmode

if !empty(globpath(&rtp, 'colors/palenight.vim'))
	colorscheme palenight
endif
"}}}
" Autocommands{{{
" Fold config files
autocmd FileType vim setlocal foldmethod=marker foldlevel=0
autocmd FileType sh setlocal foldmethod=marker foldlevel=0
autocmd FileType tmux setlocal foldmethod=marker foldlevel=0
autocmd FileType markdown setlocal spell

" Show spelling errors in commits
autocmd FileType gitcommit setlocal spell

" Based on https://stackoverflow.com/questions/26962999/wrong-indentation-when-editing-yaml-in-vim
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType py setlocal expandtab smarttab

" Toggle relative line number based on focus
autocmd FocusGained * set relativenumber number
autocmd FocusLost * set norelativenumber number

" Reload vim on save
autocmd! BufWritePost vimrc source ~/.vimrc

if has("nvim")
	autocmd TermOpen * setlocal relativenumber! number!
endif
"}}}
" Configure the status bar {{{
let g:lightline = {
	\ 'colorscheme': 'palenight',
	\ 'active': {
	\ 'left': [
	\ 	[ 'mode', 'paste' ],
	\	[ 'readonly', 'filename', 'modified' ],
	\	[ 'gitbranch' ]
	\ ],
	\ 'right': [
	\ 	[ 'linter_checking', 'linter_errors', 'linter_warnings', 'linter_ok' ],
	\	[ 'lineinfo', 'percent' ], 
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
	\	'gitbranch': 'fugitive#head',
	\   'blame': 'LightLineBlame'
	\ },
    \ }

" Ale statusline
let g:lightline.component_expand = {
      \  'linter_checking': 'lightline#ale#checking',
      \  'linter_warnings': 'lightline#ale#warnings',
      \  'linter_errors': 'lightline#ale#errors',
      \  'linter_ok': 'lightline#ale#ok',
       \ }

let g:lightline.component_type = {
      \     'linter_checking': 'left',
      \     'linter_warnings': 'warning',
      \     'linter_errors': 'error',
      \     'linter_ok': 'left',
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

function! LightLineBlame()
	let l:blame = gitblame#commit_summary(expand('%'), line('.'))
	if has_key(l:blame, "error")
		return ' '
	else
		" return blame['summary'] . ' [' . blame['author'] . ']'
		return blame['author']
	endif
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
