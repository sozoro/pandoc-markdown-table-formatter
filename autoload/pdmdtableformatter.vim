function! s:zip2ListsWith(f, l1, l2) abort
  if len(a:l1) <= len(a:l2)
    let l:minSize = len(a:l1)
  else
    let l:minSize = len(a:l2)
  endif

  let l:res = []
  let l:i   = 0
  while l:i < l:minSize
    let l:res = l:res + [a:f(a:l1[l:i], a:l2[l:i])]
    let l:i   = l:i   + 1
  endwhile

  return l:res
endfunction

function! s:extend(l1, l2, e) abort
  let l:r = a:l1
  let l:i = 0
  while l:i < len(a:l2) - len(a:l1)
    let l:r = l:r + [a:e(l:i)]
    let l:i = l:i + 1
  endwhile
  return l:r
  " return a:l1 + repeat([a:e], len(a:l2) - len(a:l1))
endfunction

function! s:zip2ExtListsWith(f, l1, l2, e) abort
  return s:zip2ListsWith(a:f, s:extend(a:l1, a:l2, a:e), a:l2)
endfunction

let s:wlal0 = { "wlen" : 0, "algn" : 0 }

function! s:zipAlgn(bar, algn) abort
  let l:algn = a:algn
  if l:algn == 0
    if a:bar[0] == ":"
      let l:algn = or(l:algn, 1)
    endif
    if a:bar[len(a:bar) - 1] == ":"
      let l:algn = or(l:algn, 2)
    endif
  endif
  return l:algn
endfunction

function! s:mapDict(dict, key, f) abort
  let l:dict = a:dict
  let l:dict[a:key] = a:f(l:dict[a:key])
  return l:dict
endfunction

function! s:maxWordLengths(tableHeadLineNum) abort
  let l:lastLineNum      = line("$")
  let l:i                = a:tableHeadLineNum
  let l:mlens            = []
  let l:algns            = []

  while l:i <= lastLineNum
    let l:l = getline(l:i)

    if     l:l[0] == "+"
      let l:bars  = split(l:l, "+")
      let s:zippr = {wlal, bar -> s:mapDict(wlal, "algn", function("s:zipAlgn",[bar]))}
      let l:algns = s:zip2ExtListsWith(s:zippr, l:algns, l:bars, {_ -> copy(s:wlal0)})
    elseif l:l[0] == "|"
      let l:elems = split(l:l, "|")
      let l:llens = map(l:elems, 'strwidth(substitute(v:val, ''\s'', "", "g"))')
      let l:mlens = s:zip2ExtListsWith({x, y -> max([x, y])}, l:mlens, l:llens, {_ -> 0})
    else
      break
    endif

    let l:i = l:i + 1
  endwhile

  echo map(deepcopy(l:algns),'v:val["algn"]')
  return l:mlens
endfunction

function! s:defaultStr(str, def) abort
  if a:str == "" | let l:str = a:def | else | let l:str = a:str | endif
  return l:str
endfunction

function! s:format(l, sep, mlens, f) abort
  let l:strs = split(a:l, a:sep)
  let l:strs = s:zip2ExtListsWith(a:f, l:strs, a:mlens, {_ -> ""})
  return a:sep . join(l:strs, a:sep) . a:sep
endfunction

function! s:formatBarLength(bc, b, n) abort
  let l:l = s:defaultStr(a:b[0], a:bc)
  let l:r = s:defaultStr(a:b[len(a:b) - 1], a:bc)
  return l:l . repeat(a:bc, a:n) . l:r
endfunction

function! s:formatWordLength(w, n) abort
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
