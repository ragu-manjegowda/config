let g:os = substitute(system('uname'), '\n', '', '')

function! PrintError(msg) abort
    execute 'normal! \<Esc>'
    echohl ErrorMsg
    echomsg a:msg
    echohl None
endfunction

if g:os == "Darwin"
    " path to directory where library can be found
    let g:clang_library_path='/Users/ragu/Documents/homebrew/opt/llvm/lib'
    let g:python_host_prog='/Users/ragu/Documents/homebrew/bin/python2'
    let g:python3_host_prog='/Users/ragu/Documents/homebrew/bin/python3'
elseif g:os == "Linux"
    " path to directory where library can be found
    let g:clang_library_path='/home/ragu/Documents/homebrew/opt/llvm/lib'
else
    :call PrintError("OS not supported to use clang_complete!")
endif