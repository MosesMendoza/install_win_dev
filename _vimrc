set vb

autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
highlight ExtraWhitespace ctermbg=red guibg=red
" Show trailing whitespace:
match ExtraWhitespace /\s\+$/

" Show trailing whitepace and spaces before a tab:
match ExtraWhitespace /\s\+$\| \+\ze\t/

" Show tabs that are not at the start of a line:
match ExtraWhitespace /[^\t]\zs\t\+/

" Show spaces used for indenting (so you use only tabs for indenting).
match ExtraWhitespace /^\t*\zs \+/

" Switch off :match highlighting.
match ExtraWhitespace /\s\+\%#\@<!$/

" Set syntax for rake files
au BufRead,BufNewFile *.rake set filetype=ruby

" Turned off cursorline but may bring it back
" set cursorline

syntax enable
set guifont=Inconsolata:h16
set number
set tabstop=2
set softtabstop=2
set shiftwidth=2
set listchars=tab:\ \ ,trail:·
set noerrorbells
set nolist
set ruler
set smartindent
set autoindent
set expandtab

" Most linux & brew distributions have something like this set already
" Makes backspace behave like most other applications, much to the chagrin of
" vim purists
set backspace=indent,eol,start

call pathogen#infect()

" Give a shortcut key to NERD Tree
map <F2> :NERDTreeToggle<CR>


