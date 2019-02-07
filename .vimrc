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
Plug 'w0rp/ale'
Plug 'maximbaz/lightline-ale'

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
set wildignore=*.o,*.pyc,*.class,*.jar,*.exe,*.a,*.dll,*.so,*/node_modules/*,*.swp,*.docx
set conceallevel=2

let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_show_hidden = 1
"}}}
" Key bindings{{{
nmap <leader>l :set relativenumber!<enter> :set number!<enter>
nmap <leader>n :NERDTreeToggle<enter>
nmap <leader>i :set list!<enter>
nmap <leader>p :CtrlPBuffer<enter>
nmap <leader>r :source ~/.vimrc<enter> :echo "Config reloaded"<enter>
nmap <leader>c :noh<enter>

" Switch vim windows
map <C-j> <Esc><C-W>j
map <C-k> <Esc><C-W>k
map <C-l> <Esc><C-W>l
map <C-h> <Esc><C-W>h

" Switch buffer easliy
nmap <Tab> :bnext<enter>
nmap <S-Tab> :bprev<enter>

" Flip through the location and quickfix lists
nmap ]l :lnext<enter>
nmap [l :lprev<enter>
nmap ]c :cnext<enter>
nmap [c :cprev<enter>


" Terminal mode
if has("nvim")
	if has("windows")
		nmap \t :vsplit term://powershell<enter>
	else
		nmap \t :vsplit term://bash<enter>
	endif
endif

tnoremap <Esc> <C-\><C-n>
" }}}
" Commands {{{
command! Todo :vimgrep /TODO/ **/*.*<enter>
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
	\ 	[ 'fileformat', 'filetype' ]
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
