""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"   Filename: .vimrc                                                         "
" Maintainer: Michael J. Smalley <michaeljsmalley@gmail.com>                 "
"        URL: http://github.com/michaeljsmalley/dotfiles                     "
"                                                                            "
"                                                                            "
" Sections:                                                                  "
"   01. General ................. General Vim behavior                       "
"   02. Events .................. General autocmd events                     "
"   03. Theme/Colors ............ Colors, fonts, etc.                        "
"   04. Vim UI .................. User interface behavior                    "
"   05. Text Formatting/Layout .. Text, tab, indentation related             "
"   06. Custom Commands ......... Any custom command aliases                 "
"   07. Plugin Configuration .... Plugin-specific settings                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 01. General                                                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible         " get rid of Vi compatibility mode. SET FIRST!
set paste                " always use paste mode

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 02. Events                                                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on " filetype detection[ON] plugin[ON] indent[ON]

" In Makefiles DO NOT use spaces instead of tabs
autocmd FileType make setlocal noexpandtab
" In Ruby files, use 2 spaces instead of 4 for tabs
autocmd FileType ruby setlocal sw=2 ts=2 sts=2

" Enable omnicompletion (to use, hold Ctrl+X then Ctrl+O while in Insert mode.
set ofu=syntaxcomplete#Complete

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 03. Theme/Colors                                                           "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set t_Co=256              " enable 256-color mode.
if has('termguicolors')
  set termguicolors
endif
syntax enable             " enable syntax highlighting (previously syntax on).
let g:tokyonight_style = 'night'

function! s:ApplyTokyonightOverrides() abort
  highlight Normal guifg=#ddd3cf guibg=#2b2d31 ctermfg=252 ctermbg=236
  highlight Terminal guifg=#ddd3cf guibg=#2b2d31 ctermfg=252 ctermbg=236
  highlight EndOfBuffer guifg=#2b2d31 guibg=#2b2d31 ctermfg=236 ctermbg=236
  highlight FoldColumn guifg=#85777f guibg=#24262a ctermfg=243 ctermbg=235
  highlight Folded guifg=#85777f guibg=#24262a ctermfg=243 ctermbg=235
  highlight SignColumn guifg=#ddd3cf guibg=#24262a ctermfg=252 ctermbg=235
  highlight LineNr guifg=#85777f guibg=#2b2d31 ctermfg=243 ctermbg=236
  highlight CursorLineNr guifg=#ddd3cf guibg=#33353a ctermfg=252 ctermbg=237
  highlight CursorLine guibg=#33353a ctermbg=237
  highlight CursorColumn guibg=#33353a ctermbg=237
  highlight ColorColumn guibg=#33353a ctermbg=237
  highlight VertSplit guifg=#24262a guibg=#2b2d31 ctermfg=235 ctermbg=236
  highlight WinSeparator guifg=#24262a guibg=#2b2d31 ctermfg=235 ctermbg=236
  highlight StatusLine guifg=#ddd3cf guibg=#33353a ctermfg=252 ctermbg=237
  highlight StatusLineNC guifg=#85777f guibg=#24262a ctermfg=243 ctermbg=235
  highlight NormalFloat guifg=#ddd3cf guibg=#24262a ctermfg=252 ctermbg=235
  highlight Pmenu guifg=#ddd3cf guibg=#24262a ctermfg=252 ctermbg=235
  highlight PmenuSel guifg=#2b2d31 guibg=#98c379 ctermfg=236 ctermbg=114
  highlight Comment term=NONE guifg=#85777f ctermfg=243 gui=italic cterm=italic
  highlight Delimiter term=NONE guifg=#85777f ctermfg=243 gui=NONE cterm=NONE
  highlight Operator term=NONE guifg=#85777f ctermfg=243 gui=NONE cterm=NONE
  highlight Type term=NONE guifg=#78a9ff ctermfg=111 gui=NONE cterm=NONE
  highlight Typedef term=NONE guifg=#78a9ff ctermfg=111 gui=NONE cterm=NONE
  highlight StorageClass term=NONE guifg=#78a9ff ctermfg=111 gui=NONE cterm=NONE
endfunction

augroup goings_tokyonight
  au!
  autocmd ColorScheme tokyonight call s:ApplyTokyonightOverrides()
augroup END

colorscheme tokyonight    " set colorscheme
call s:ApplyTokyonightOverrides()

" Highlight Python indentation errors
autocmd FileType python highlight PythonIndentError ctermbg=red guibg=red
autocmd FileType python match PythonIndentError /^\(\s\{,3}\)\@<!\s\{,3}\S\|^\(\s\{4}\)*\zs\s\{1,3}\S/

" Prettify JSON files
autocmd BufRead,BufNewFile *.json set filetype=json
autocmd Syntax json sou ~/.vim/syntax/json.vim

" Prettify Vagrantfile
autocmd BufRead,BufNewFile Vagrantfile set filetype=ruby

" Prettify Markdown files
augroup markdown
  au!
  au BufNewFile,BufRead *.md,*.markdown setlocal filetype=ghmarkdown
augroup END

" PSI4 files *.dat as with Python syntax
au BufReadPost *.dat set syntax=python

" Highlight characters that go over 80 columns (by drawing a border on the 81st)
if exists('+colorcolumn')
  set colorcolumn=121
  highlight ColorColumn guibg=#33353a ctermbg=237
else
  highlight OverLength ctermfg=NONE ctermbg=237 guibg=#33353a
  match OverLength /\%81v.\+/
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 04. Vim UI                                                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set number                " show line numbers
set relativenumber        " show relative line numbers
set numberwidth=2         " make the number gutter 6 characters wide
set cul                   " highlight current line
set laststatus=2          " last window always has a statusline
set nohlsearch            " Don't continue to highlight searched phrases.
set incsearch             " But do highlight as you type your search.
set ignorecase            " Make searches case-insensitive.
set smartcase             " Case-sensitive if search contains uppercase
set ruler                 " Always show info along bottom.
set showmatch
set statusline=%<%f\%h%m%r%=%-20.(line=%l\ \ col=%c%V\ \ totlin=%L%)\ \ \%h%m%r%=%-40(bytval=0x%B,%n%Y%)\%P
set visualbell
set wildmenu              " Enhanced command completion
set wildmode=longest:full,full
set scrolloff=2           " Keep 8 lines above/below cursor
set sidescrolloff=2       " Keep 8 columns left/right of cursor
"set clipboard=unnamed     " Use system clipboard for yank/put operations

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 05. Text Formatting/Layout                                                 "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autoindent            " auto-indent
set tabstop=4             " tab spacing
set softtabstop=4         " unify
set shiftwidth=4          " indent/outdent by 4 columns
set shiftround            " always indent/outdent to the nearest tabstop
set expandtab             " use spaces instead of tabs
set smartindent           " automatically insert one extra level of indentation
set smarttab              " use tabs at the start of a line, spaces elsewhere
"set nowrap                " don't wrap text
"set textwidth=80

" Persistent undo
set undofile
set undodir=~/.vim/undodir
if !isdirectory(&undodir)
    call mkdir(&undodir, 'p')
endif

" Better backup and swap file handling
set backup
set backupdir=~/.vim/backup
set writebackup
set swapfile
set directory=~/.vim/swap
if !isdirectory(&backupdir)
    call mkdir(&backupdir, 'p')
endif
if !isdirectory(&directory)
    call mkdir(&directory, 'p')
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 06. Custom Commands                                                        "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Prettify JSON files making them easier to read
command PrettyJSON %!python -m json.tool

" Key mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Quick escape from insert mode
inoremap jk <Esc>

" Clear search highlighting
nnoremap <leader>/ :nohlsearch<CR>

" Put these lines at the very end of your vimrc file.
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 07. Plugin Configuration                                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Plugins will be downloaded under the specified directory.
call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')

" Essential plugins
Plug 'tpope/vim-sensible'
Plug 'junegunn/seoul256.vim'

" File navigation and search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'preservim/nerdtree'

" Activity logging
Plug 'ActivityWatch/aw-watcher-vim'

" Git integration
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Enhanced editing
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'

" Status line
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Language support
Plug 'sheerun/vim-polyglot'

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

" Plugin-specific configurations

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.git$', '\.DS_Store$', '__pycache__']

" FZF
nnoremap <leader>p :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>l :Lines<CR>

" Airline configuration
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 0

function! GoingsAirlinePatch(palette) abort
  let l:section_b = [ '#ddd3cf', '#33353a', 252, 237 ]
  let l:section_c = [ '#85777f', '#2b2d31', 243, 236 ]
  let l:inactive = [ '#85777f', '#24262a', 243, 235 ]

  let a:palette.normal = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#98c379', 236, 114, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.insert = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#ff9f43', 236, 215, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.visual = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#5ea1ff', 236, 75, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.replace = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#ff6b6b', 236, 203, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.commandline = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#c792ea', 236, 176, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.terminal = airline#themes#generate_color_map(
        \ [ '#2b2d31', '#c792ea', 236, 176, 'bold' ],
        \ l:section_b,
        \ l:section_c)
  let a:palette.inactive = airline#themes#generate_color_map(l:inactive, l:inactive, l:inactive)
  let a:palette.accents = extend(get(a:palette, 'accents', {}), {
        \ 'red': [ '#ff6b6b', '', 203, '' ],
        \ 'green': [ '#98c379', '', 114, '' ],
        \ 'blue': [ '#5ea1ff', '', 75, '' ],
        \ 'orange': [ '#ff9f43', '', 215, '' ],
        \ 'purple': [ '#c792ea', '', 176, '' ],
        \ }, 'force')
endfunction

let g:airline_theme = 'minimalist'
let g:airline_theme_patch_func = 'GoingsAirlinePatch'

" Keep git noise low but retain location context
let g:airline#extensions#hunks#enabled = 0        " Remove +0 ~3 -0
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#gitgutter#enabled = 0    " Remove git indicators

let g:airline_section_a = airline#section#create(['mode'])
let g:airline_section_b = airline#section#create(['branch'])
let g:airline_section_c = airline#section#create(['readonly', 'filename'])
let g:airline_section_x = ''
let g:airline_section_y = ''
let g:airline_section_z = '%p%% L:%l C:%c'
let g:airline_section_error = ''
let g:airline_section_warning = ''

" GitGutter configuration
set updatetime=100

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
" packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
