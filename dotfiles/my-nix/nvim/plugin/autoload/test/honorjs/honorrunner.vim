" Returns true if the given file belongs to your test runner
function! test#honorjs#honorrunner#test_file(file) abort
    return a:file =~ "\.test\.js" || a:file =~ "\.test\.jsx" || a:file =~ "\.test\.tsx" || a:file =~ "\.test\.ts"
endfunction

function! test#honorjs#honorrunner#build_position(type, position) abort
  if a:type ==# 'nearest'
    let name = s:nearest_test(a:position)
    if !empty(name)
      let name = '-t '.shellescape(name, 1)
    endif
    return ['--no-coverage', name, a:position['file']]
  elseif a:type ==# 'file'
    return ['--no-coverage', a:position['file']]
  else
    return []
  endif
endfunction

function! s:nearest_test(position) abort
  let name = test#base#nearest_test(a:position, g:test#javascript#patterns)
  return (len(name['namespace']) ? '^' : '') .
       \ test#base#escape_regex(join(name['namespace'] + name['test'])) .
       \ (len(name['test']) ? '$' : '')
endfunction

" Returns processed args (if you need to do any processing)
function! test#honorjs#honorrunner#build_args(args) abort
    let args = a:args
    return args
endfunction

" Returns the executable of your test runner
function! test#honorjs#honorrunner#executable() abort
    return "yarn test"
endfunction
