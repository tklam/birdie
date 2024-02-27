let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

let g:birdie_info_buffer_name = "birdie_info"
let g:birdie_one_module_buffer_name = "birdie_one_module"

if has("python3")
    command! -nargs=1 Py py3 <args>
    let s:python_command = "python3"
else
    command! -nargs=1 Py py <args>
    let s:python_command = "python"
endif

" init the plugin
"-----------------------------------------------------------------
Py << EOF
from __future__ import print_function
import sys
from os.path import normpath, join
import vim

plugin_root_dir = normpath(join(vim.eval('s:plugin_root_dir'), '..'))
python_root_dir = normpath(join(plugin_root_dir, 'python'))
print(python_root_dir)
sys.path.insert(0, python_root_dir)

import birdie
birdie.init(plugin_root_dir)

EOF
"-----------------------------------------------------------------


"-----------------------------------------------------------------
function! birdie#hello()
Py birdie.hello()
endfunction


"-----------------------------------------------------------------
function! birdie#go_to_window(winid)
if exists('*win_findbuf') == 1
    call win_gotoid(a:winid)
else
    exe a:winid 'wincmd w'
endif
endfunction


"-----------------------------------------------------------------
function! birdie#get_window_by_buf_name(buffer_name)
let l:matched_win_nr = -1
if exists('*win_findbuf') == 1
    " win_findbuf and win_gotoid are available  only after Vim 8.0
    let l:bnr=bufnr(a:buffer_name) " get buffer number
    let l:wids=win_findbuf(l:bnr)
    if l:bnr == -1 || len(l:wids) == 0
        let l:matched_win_nr = -1
    else
        let l:matched_win_nr = l:wids[0]
    endif
else
    let l:bufwinnr=bufwinnr(a:buffer_name) " get window number
    if l:bufwinnr <= 0
        let l:matched_win_nr = -1
    else
        let l:matched_win_nr = l:bufwinnr
    endif
endif
return l:matched_win_nr
endfunction


"-----------------------------------------------------------------
function! birdie#create_or_open_window(position, buffer_name, window_size)
let l:matched_win_nr = birdie#get_window_by_buf_name(a:buffer_name)
if l:matched_win_nr == -1
    " not found
    exe a:position . ' new' a:buffer_name
    set buftype=nofile
else
    call birdie#go_to_window(l:matched_win_nr)
endif
Py << EOF
if int(vim.eval('a:window_size')) > 0:
    vim.command('resize {0}'.format(vim.eval('a:window_size')))
EOF
" This piece of Vim script doesn't work in Neovim 0.3.4
" So the above Python script is used as a workaround
"
" if a:window_size > 0
"    resize a:window_size
endfunction


"-----------------------------------------------------------------
function! birdie#replace_buffer_content(buffer_name, new_content)
let l:matched_win_nr = birdie#get_window_by_buf_name(a:buffer_name)
" assume the window is already opened
call birdie#go_to_window(l:matched_win_nr)
normal! gg_dG
call setline(1, split(a:new_content, '\n'))
endfunction


"-----------------------------------------------------------------
function! birdie#parse_current_verilog(limit_to_use_defined_modules)
let l:cur_file_path = expand('%:p')
echom "Parsing " . l:cur_file_path
echom " show only user defined modules? " . a:limit_to_use_defined_modules
Py birdie.parse_verilog(vim.eval('l:cur_file_path'), vim.eval('a:limit_to_use_defined_modules'))
echom "Done"
endfunction
command! -nargs=0 Parse call birdie#parse_current_verilog(1)
command! -nargs=0 ParseAll call birdie#parse_current_verilog(0)


"-----------------------------------------------------------------
function! birdie#show_current_module_info()
let l:cur_file_path = expand('%:p')
let l:cur_line_number = line('.')
let l:prev_window=birdie#get_window_by_buf_name(l:cur_file_path)
echom "Getting the module that we are in:" . l:cur_file_path . ' line: ' . l:cur_line_number
Py << EOF
v_module = birdie.get_module_by_line_number(vim.eval('l:cur_file_path'), vim.eval('l:cur_line_number'))
if v_module is not None:
    print('Current module: {0}'.format(v_module._module_name))
    vim.command('call birdie#create_or_open_window("{0}", "{1}", 10)'.format('rightbelow', vim.eval('g:birdie_info_buffer_name')))
    module_str = str(v_module)
    vim.command('call birdie#replace_buffer_content("{0}", "{1}")'.format(vim.eval('g:birdie_info_buffer_name'), module_str))
else:
    print('Current module: None')
EOF
call birdie#go_to_window(l:prev_window)
endfunction
command! -nargs=0 Module call birdie#show_current_module_info()


"-----------------------------------------------------------------
function! birdie#go_to_module_by_name(module_name)
let l:found_module = 0
echom "Hopping to the definition of module: " . a:module_name
Py << EOF
candidate_module_names, v_module = birdie.get_module_by_name(vim.eval('a:module_name'))
if v_module is not None:
    vim.command('let l:found_module = 1')
    vim.command('b ' + v_module._file_path)
    vim.command('normal ' + str(v_module._file_begin_line_number) + 'G')
    print('There is one matching instance path:')
    print('  {0}'.format(candidate_module_names[0]))
else:
    if len(candidate_module_names) == 0:
        print('Cannot find module with module name {0}.'.format(vim.eval('a:module_name')))
        print('Please parse the Verilog file containing the module by opening the file and then ":Parse".')
    else:
        print('There are more than one matching module_names:')
        for i in candidate_module_names:
            print('  {0}'.format(i))
EOF
return l:found_module 
endfunction

function! birdie#go_to_module_by_instance_path(instance_path)
let l:found_module = 0
echom "Hopping to the definition of module with instance path: " . a:instance_path
Py << EOF
candidate_instance_paths, v_module = birdie.get_module_by_instance_path(vim.eval('a:instance_path'))
if v_module is not None:
    vim.command('let l:found_module = 1')
    print('There is one matching instance path:')
    print('  {0}'.format(candidate_instance_paths[0]))
    vim.command('b {0}'.format(v_module._file_path))
    vim.command('normal {0}G'.format(v_module._file_begin_line_number))
else:
    if len(candidate_instance_paths) == 0:
        print('Cannot find module with instance path {0}.'.format(vim.eval('a:instance_path')))
        print('Please parse the Verilog file containing the module by opening the file and then ":Parse".')
    else:
        print('There are more than one matching instance paths:')
        for i in candidate_instance_paths:
            print('  {0}'.format(i))
EOF
return l:found_module 
endfunction

function! birdie#go_to_module(name_or_instance_path)
    if birdie#go_to_module_by_name(a:name_or_instance_path) == 0
        call birdie#go_to_module_by_instance_path(a:name_or_instance_path)
    endif
endfunction

command! -nargs=1 GotoModule call birdie#go_to_module(<f-args>)


function! birdie#go_to_instance(instance_path)
let l:found_parent_module = 0
let l:parent_module_instance_path = ""
let l:target_instance_name = ""
let l:target_instance_name_line_number = 0
echom "Hopping to the declaration of instance: " . a:instance_path

Py << EOF
path_segments = vim.eval('a:instance_path').split('/')
vim.command('let l:parent_module_instance_path = "{0}"'.format('/'.join(path_segments[0:-1])))
vim.command('let l:target_instance_name = "{0}"'.format(path_segments[-1]))
EOF

echom "  parent module/instance: " . l:parent_module_instance_path
echom "  target instance: " . l:target_instance_name

Py << EOF
# an item in candidate_instance_paths can be the name of the top module or an instance path
parent_module_or_path = vim.eval('l:parent_module_instance_path')
candidate_instance_paths, v_module = birdie.get_module_by_name(parent_module_or_path)
if v_module is None:
    if parent_module_or_path == '':
        print('Cannot determin the parent module/instance path')
        pass
    candidate_instance_paths, v_module = birdie.get_module_by_instance_path(parent_module_or_path)

if v_module is not None:
    vim.command('let l:found_parent_module = 1')
    print('Identified the definition of the parent module:')
    print('  <{0}> {1}'.format(v_module._module_name, candidate_instance_paths[0]))
    print('')
    vim.command('b {0}'.format(v_module._file_path))
    vim.command('normal {0}G'.format(v_module._file_begin_line_number))
    vim.command('let l:target_instance_name_line_number = search(l:target_instance_name,"cW", {0})'
            .format(v_module._file_end_line_number))
    vim.command('echom l:target_instance_name_line_number')
    vim.command('normal {0}G'.format(vim.eval('l:target_instance_name_line_number')))
else:
    if len(candidate_instance_paths) == 0:
        print('Cannot find the parent module whose instance path is: {0}.'.format(parent_module_or_path))
        print('Please parse the Verilog file containing the module by opening the file and then ":Parse".')
    else:
        print('There are more than one matching instance paths of the parent module:')
        for i in candidate_instance_paths:
            print('  {0}'.format(i))
EOF
endfunction
command! -nargs=1 GotoInstance call birdie#go_to_instance(<f-args>)


"-----------------------------------------------------------------
function! birdie#extract_single_module(module_name)
let l:found_module = 0
echom "Extracting the definition of " . a:module_name
Py << EOF
candidate_module_names, v_module = birdie.get_module_by_name(vim.eval('a:module_name'))
if v_module is not None:
    vim.command('let l:found_module = 1')
    print('There is one matching instance path:')
    print('  {0}'.format(candidate_module_names[0]))
    vim.command('b {0}'.format(v_module._file_path))
    vim.command('{0},{1}y'.format(v_module._file_begin_line_number, v_module._file_end_line_number))
    vim.command('call birdie#create_or_open_window("{0}", "{1}.{2}", -1)'.format('vertical rightbelow', vim.eval('g:birdie_one_module_buffer_name'), candidate_module_names[0]))
    header = '// {0} from line {1} to {2}: {3}'.format(
            v_module._file_path, v_module._file_begin_line_number, v_module._file_end_line_number, v_module._module_name) 
    vim.command('call birdie#replace_buffer_content("{0}", "{1}")'.format(vim.eval('g:birdie_one_module_buffer_name'), header))
    vim.command('normal "0p')
else:
    if len(candidate_module_names) == 0:
        print('Cannot find module with module name {0}.'.format(vim.eval('a:module_name')))
        print('Please parse the Verilog file containing the module by opening the file and then ":Parse".')
    else:
        print('There are more than one matching module_names:')
        for i in candidate_module_names:
            print('  {0}'.format(i))
EOF
return l:found_module
endfunction
command! -nargs=1 OneModule call birdie#extract_single_module(<f-args>)


"-----------------------------------------------------------------
function! birdie#print_hierarchy()
let l:hier_content = ""
Py << EOF
vim.command('call birdie#create_or_open_window("{0}", "{1}", 10)'.format('rightbelow', vim.eval('g:birdie_info_buffer_name')))
vim.command('call birdie#replace_buffer_content("{0}", "{1}")'
        .format(vim.eval('g:birdie_info_buffer_name'), birdie.get_design_hierarchy_str()))
EOF
endfunction
command! -nargs=0 Hierarchy call birdie#print_hierarchy()


"-----------------------------------------------------------------
call birdie#hello()

" nmap <buffer> <C-p> :call birdie#parse_current_verilog(1)

let g:birdie_loaded = 1
" Not used. The user can modify and reload this script without quiting vim. However, online changes made to the underlying Python scripts can only be reloaded by restarting vim.
