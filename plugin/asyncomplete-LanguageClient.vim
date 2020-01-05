" LSP source for asyncomplete.vim - LanguageClient-neovim
" Last Change: 2020 Jan 05
" Maintainer: Bernd Busse @tryone144
" License: This plugin is licensed under the MIT license

if exists('g:asyncomplete_LanguageClient_loaded')
    finish
endif
let g:asyncomplete_LanguageClient_loaded = 1

let s:LanguageClient_started = 0
let s:registered_servers = {} " { filetype: enabled }


" Handle startup/shutdown of LanguageClient backend
augroup asyncomplete_LanguageClient_setup
    autocmd!
    " TODO: Only call when enabled (asyncomplete_LanguageClient_autostart)
    autocmd User LanguageClientStarted call s:handle_lc_started()
    autocmd User LanguageClientStopped call s:handle_lc_stopped()
    autocmd FileType * call s:register_LanguageClient('<amatch>')
augroup END

" Handle startup of LanguageClient backend
function! s:handle_lc_started() abort
    " register completion provider for all existing buffers
    let l:filetypes = uniq(map(
                \ filter(range(1, bufnr('$')), 'bufexists(v:val)'),
                \ 'getbufvar(v:val, "&filetype")'))

    for l:ft in filter(l:filetypes, 'v:val != ""')
        call s:register_LanguageClient(l:ft)
    endfor
endfunction

" Handle shutdown of LanguageClient backend
function! s:handle_lc_stopped() abort
    " FIXME: most likely only a single Server stopped. Try to check which one
    " this was and only unregister this one...

    " unregister all registered completion providers
    "for l:ft in keys(s:registered_servers)
    "    call s:unregister_LanguageClient(l:ft)
    "endfor
endfunction


" Register LanguageClient as completion provider
function! s:register_LanguageClient(filetype) abort
    if get(s:registered_servers, a:filetype, 0) | return | endif

    " TODO: check global blacklist
    let l:ls_cmd = get(g:LanguageClient_serverCommands, a:filetype, [])
    if !len(l:ls_cmd)
        return
    endif

    " check if language server supports completion
    call LanguageClient#getState(function('s:register_LanguageClient_with_capabilites', [a:filetype]))
endfunction

" Unregister LanguageClient as completion provider
function! s:unregister_LanguageClient(filetype) abort
    if !get(s:registered_servers, a:filetype, 0) | return | endif

    " unregister completion provider
    call asyncomplete#unregister_source('LanguageClient_' . a:filetype)
    unlet s:registered_servers[a:filetype]
endfunction

" Register LanguageClient for `filetype` if capabilities match
function! s:register_LanguageClient_with_capabilites(filetype, result) abort
    " check for error
    if !has_key(a:result, 'result')
        if has_key(a:result, 'error')
            call asyncomplete#log('source#LanguageClient',
                        \ 'register_LanguageClient_with_capabilites(' . a:filetype . ')',
                        \ 'languageClient/getState query failed: ' . get(a:result['error'], 'message', 'unknown error'))
        else
            call asyncomplete#log('source#LanguageClient',
                        \ 'register_LanguageClient_with_capabilites(' . a:filetype . ')',
                        \ 'languageClient/getState query failed: no result returned')
        endif
        return
    endif

    " parse result
    try
        let l:state = json_decode(get(a:result, 'result'))
        if type(l:state) !=# type({})
            throw 'result is not a dict'
        endif

        if !has_key(l:state, 'capabilities') || (has_key(l:state, 'capabilities') && type(l:state['capabilities']) !=# type({}))
            throw 'result does not contain capabilities'
        endif
    catch
        call asyncomplete#log('source#LanguageClient',
                    \ 'register_LanguageClient_with_capabilites(' . a:filetype . ')',
                    \ 'Invalid languageClient/getState query result: ' . v:exception)
        return
    endtry

    let l:capabilities = get(get(l:state['capabilities'], a:filetype, {}), 'capabilities', {})
    if !has_key(l:state['capabilities'], a:filetype) || !has_key(l:capabilities, 'completionProvider')
        " language server not available for `filetype` or does not support
        " completion requests
        return
    endif

    " TODO: Support custom priorities
    let l:source_options = {
                \ 'name': 'LanguageClient_' . a:filetype,
                \ 'whitelist': [a:filetype],
                \ 'priority': 10,
                \ 'completor': function('s:completor'),
                \ }

    let l:provider = get(l:capabilities, 'completionProvider')
    if type(l:provider) ==# type({}) && has_key(l:provider, 'triggerCharacters')
        let l:source_options['triggers'] = {'*': get(l:provider, 'triggerCharacters', [])}
    endif

    " register completion provider
    call asyncomplete#register_source(l:source_options)
    let s:registered_servers[a:filetype] = 1
endfunction

" Relay completion requests to LanguageClient
function! s:completor(opt, ctx) abort
    let l:column = a:ctx['col']
    let l:keyword = matchstr(a:ctx['typed'], '\k\+$')
    let l:startcol = l:column - len(l:keyword)

    " query LanguageCLient
    call LanguageClient#omniComplete({}, function('s:handle_completion', [a:opt, a:ctx, l:startcol]))
endfunction

" Forward completion result to asyncomplete
function! s:handle_completion(opt, ctx, startcol, data) abort
    if !has_key(a:data, 'result')
        if has_key(a:data, 'error')
            call asyncomplete#log('source#LanguageClient',
                        \ 'handle_completion()',
                        \ 'completion query failed: ' . get(a:data['error'], 'message', 'unknown error'))
        endif
        return
    endif

    let l:result = get(a:data, 'result')
    if type(l:result) ==# type([])
        let l:items = l:result
    else
        call asyncomplete#log('source#LanguageClient',
                    \ 'handle_completion()',
                    \ 'unknown query result: ' . l:data)
        let l:items = []
    endif

    " send completion items to asyncomplete
    call asyncomplete#complete(a:opt['name'], a:ctx, a:startcol, l:items)
endfunction
