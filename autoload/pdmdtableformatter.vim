function! s:zip2ListsWith(f, l1, l2) abort
  if len(a:l1) <= len(a:l2)
    let l:shorter = a:l1
    let l:longer  = deepcopy(a:l2)
  else
    let l:shorter = a:l2
    let l:longer  = deepcopy(a:l1)
  endif

  let l:shorterlen = len(l:shorter)
  let l:i = 0

  while l:i < l:shorterlen
    let l:longer[l:i] = a:f(a:l1[l:i], a:l2[l:i])
    let l:i = l:i + 1
  endwhile

  return l:longer
endfunction

function! s:extend(l1, l2, e) abort
  return a:l1 + repeat([a:e], len(a:l2) - len(a:l1))
endfunction

function! s:maxWordLengths(tableHeadLineNum) abort
  let l:lastLineNum      = line("$")
  let l:i                = a:tableHeadLineNum
  let l:mlens            = []
  let l:algns            = []

  while l:i <= lastLineNum
    let l:l = getline(l:i)

    if     l:l[0] == "+"
    elseif l:l[0] == "|"
      let l:elems = split(l:l, "|")
      let l:llens = map(l:elems, 'strwidth(substitute(v:val, ''\s'', "", "g"))')
      let l:mlens = s:extend(l:mlens, l:llens, 0)
      let l:mlens = s:zip2ListsWith({x, y -> max([x, y])}, l:mlens, l:llens)
    else
      break
    endif

    let l:i = l:i + 1
  endwhile

  return l:mlens
endfunction

function! s:defaultStr(str, def) abort
  if a:str == "" | let l:str = a:def | else | let l:str = a:str | endif
  return l:str
endfunction

function! s:format(l, sep, mlens, f) abort
  let l:strs = split(a:l, a:sep)
  let l:strs = s:extend(l:strs, a:mlens, "")
  let l:strs = s:zip2ListsWith(a:f, a:mlens, l:strs)
  return a:sep . join(l:strs, a:sep) . a:sep
endfunction

function! s:formatBarLength(bc, n, b) abort
  let l:l = s:defaultStr(a:b[0], a:bc)
  let l:r = s:defaultStr(a:b[len(a:b) - 1], a:bc)
  return l:l . repeat(a:bc, a:n) . l:r
endfunction

function! s:formatWordLength(n, w) abort
  let l:str = substitute(a:w, '\s', "", "g")
  return " " . l:str . repeat(" ", a:n - strwidth(l:str)) . " "
endfunction

function! s:formatPandocMDTable(tableHeadLineNum, mlens) abort
  let l:lastLineNum      = line("$")
  let l:i                = a:tableHeadLineNum
  while l:i <= l:lastLineNum
    let l:l = getline(l:i)

    if     l:l[0] == "+"
      let l:bc   = s:defaultStr(l:l[2], "-")
      call setline(l:i, s:format(l:l, "+", a:mlens, function("s:formatBarLength",[l:bc])))
    elseif l:l[0] == "|"
      call setline(l:i, s:format(l:l, "|", a:mlens, function("s:formatWordLength")))
    else
      break
    endif

    let l:i = l:i + 1
  endwhile

  return l:i - 1
endfunction

function! pdmdtableformatter#FormatThisPandocMDTable() abort
  let l:tableHeadLineNum = line(".")
  while l:tableHeadLineNum >= 0 && getline(l:tableHeadLineNum)[0] =~ '\(+\||\)'
    let l:tableHeadLineNum = l:tableHeadLineNum - 1
  endwhile

  if l:tableHeadLineNum == line(".")
    echo "no table here"
  else
    let l:tableHeadLineNum = l:tableHeadLineNum + 1
    let l:mlens            = s:maxWordLengths(l:tableHeadLineNum)
    let l:tableLastLineNum = s:formatPandocMDTable(l:tableHeadLineNum, l:mlens)
    echo "formatted line [" . l:tableHeadLineNum . "-" . l:tableLastLineNum . "]"
  endif
endfunction
