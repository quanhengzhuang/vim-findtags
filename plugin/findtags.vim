" findtags.vim
" 2014.8.10 搜索，新窗口打开
" 参考:
" http://andrewradev.com/2011/06/08/vim-and-ctags/
" http://www.vim.org/scripts/script.php?script_id=3771
" 差异点：同时搜索函数、类、常量等, pattern优化, 生成tags命令
" 差异点：判断是行号还是pattern, 新tab打开
" 2014.8.11 增加单词高亮, 智能识别cmd
" 2014.8.12 增加zz，将搜索结果置中

if exists('g:loaded_find_tags')
    finish
endif

let g:loaded_find_tags = 1

" 快捷键ee搜索当前单词
map <leader>e :call FindInTaglistHere()<CR>
map E :call FindInTaglistInsightHere()<CR>

" 搜索命令、生成tags命令
command! -nargs=1 F call s:FindInTaglist(<f-args>)
command! -nargs=? Fmake call s:TaglistMake(<f-args>)

" 匹配关键词的高亮设置
highlight SEARCH_TAGS_NAME ctermbg=5 ctermfg=0

let g:TagInsight_PreviewWindow = 0

function! FindInTaglistHere()
    call s:FindInTaglist(expand('<cword>'))
endfunction

function! FindInTaglistInsightHere()
    call s:FindInTaglistInsight(expand('<cword>'))
endfunction

function! s:TaglistMake(...)
    let cmd = 'ctags -R'
    if (a:0 == 1)
        let cmd = cmd.' --languages='.a:1
    endif
    echohl WarningMsg | echo 'generating tags... ('.cmd.')' | echohl None
    call system(cmd)
    echohl WarningMsg | echo 'generated tags done. ('.cmd.')' | echohl None
endfunction

function! s:FindInTaglist(name)
    if (empty(tagfiles()))
        echohl WarningMsg | echo 'no found "tags" file in pwd' | echohl None
        return
    endif

    let tags = taglist('^'.a:name.'$')
    let tags = filter(tags, 'v:val["kind"] != "v"')

    if (empty(tags))
        echohl WarningMsg | echo 'no found defines' | echohl None
        return
    endif

    "设置quickfix
    let quickfix = []
    for i in tags
        if (str2nr(i.cmd) > 0 && strlen(i.cmd) == strlen(str2nr(i.cmd)))
            call add(quickfix, {'lnum' : i.cmd, 'filename' : i.filename, 'text' : i.kind})
        else
            let pattern = strpart(i.cmd, 2, strlen(i.cmd) - 4)
            let pattern = escape(pattern, '*[]')
            call add(quickfix, {'pattern' : pattern, 'filename' : i.filename, 'text' : i.kind})
        endif
    endfor
    call setqflist(quickfix)

    tabnew
    "tabdo cclose
    if len(quickfix) > 1
        copen
        if len(quickfix) < 5
            :resize 5
        endif
    endif

    set nowrap
    cfirst
    execute 'normal zz'
    call matchadd('SEARCH_TAGS_NAME', '\<'.a:name.'\>')
endfunction

function! s:FindInTaglistInsight(name)
    if (empty(tagfiles()))
        echohl WarningMsg | echo 'no found "tags" file in pwd' | echohl None
        return
    endif

    let tags = taglist('^'.a:name.'$')
    let tags = filter(tags, 'v:val["kind"] != "v"')

    if (empty(tags))
        echohl WarningMsg | echo 'no found defines' | echohl None
        return
    endif

    call matchadd('SEARCH_TAGS_NAME', '\<'.a:name.'\>')

    " 设置quickfix
    let quickfix = []
    for i in tags
        if (str2nr(i.cmd) > 0 && strlen(i.cmd) == strlen(str2nr(i.cmd)))
            call add(quickfix, {'lnum' : i.cmd, 'filename' : i.filename, 'text' : i.kind})
        else
            let pattern = strpart(i.cmd, 2, strlen(i.cmd) - 4)
            let pattern = escape(pattern, '*[]')
            call add(quickfix, {'pattern' : pattern, 'filename' : i.filename, 'text' : i.kind})
        endif
    endfor
    call setqflist(quickfix)

    only
    copen
    set nowrap

    vsplit
    cfirst
    let g:TagInsight_PreviewWindow = bufnr('%')
    call matchadd('SEARCH_TAGS_NAME', '\<'.a:name.'\>')
    execute 'normal zt'
endfunction
