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
endfunction

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

function! s:delSpacesBA(str) abort
  return substitute(a:str, '^\s*\(.\{-}\)\s*$', '\1', "")
endfunction

function! s:zipWLen(str, wlen) abort
  return max([a:wlen, strwidth(s:delSpacesBA(a:str))])
endfunction

function! s:mapDict(dict, key, f) abort
  let l:dict = a:dict
  let l:dict[a:key] = a:f(l:dict[a:key])
  return l:dict
endfunction

let s:wlal0 = { "wlen" : 0, "algn" : 0 }

function! s:updateWLALs(wlals, line, key, sep, fname) abort
  let l:strs  = split(a:line, a:sep)
  let l:strs  = s:extend(l:strs, a:wlals, {_ -> ""           })
  let l:wlals = s:extend(a:wlals, l:strs, {_ -> copy(s:wlal0)})
  let s:zippr = {wlal, str -> s:mapDict(wlal, a:key, function(a:fname,[str]))}
  return s:zip2ListsWith(s:zippr, l:wlals, l:strs)
endfunction

function! s:wordLengthsAndAligns(tableHeadLineNum) abort
  let l:lastLineNum      = line("$")
  let l:wlals            = []
  let l:i                = a:tableHeadLineNum

  while l:i <= lastLineNum
    let l:l = getline(l:i)

    if     l:l[0] == "+"
      let l:wlals = s:updateWLALs(l:wlals, l:l, "algn", "+", "s:zipAlgn")
    elseif l:l[0] == "|"
      let l:wlals = s:updateWLALs(l:wlals, l:l, "wlen", "|", "s:zipWLen")
    else
      break
    endif

    let l:i = l:i + 1
  endwhile

  return l:wlals
endfunction

function! s:defaultStr(str, def) abort
  if a:str == "" | let l:str = a:def | else | let l:str = a:str | endif
  return l:str
endfunction

function! s:format(l, sep, wlals, f) abort
  let l:strs = split(a:l, a:sep)
  let l:strs = s:extend(l:strs, a:wlals, {_ -> ""})
  let l:strs = s:zip2ListsWith(a:f, l:strs, a:wlals)
  return a:sep . join(l:strs, a:sep) . a:sep
endfunction

function! s:formatBarLength(bc, b, wlal) abort
  let l:l = s:defaultStr(a:b[0], a:bc)
  let l:r = s:defaultStr(a:b[len(a:b) - 1], a:bc)
  return l:l . repeat(a:bc, a:wlal["wlen"]) . l:r
endfunction

function! s:formatWordLength(w, wlal) abort
  let l:str  = s:delSpacesBA(a:w)
  let l:diff = a:wlal["wlen"] - strwidth(l:str)

  if     a:wlal["algn"] == 2
    let l:str = repeat(" ", l:diff) . l:str
  elseif a:wlal["algn"] == 3
    let l:half = l:diff / 2
    let l:str  = repeat(" ", l:diff - l:half) . l:str . repeat(" ", l:half)
  else
    let l:str = l:str . repeat(" ", l:diff)
  endif

  return " " . l:str . " "
endfunction

function! s:formatPandocMDTable(tableHeadLineNum, wlals) abort
  let l:lastLineNum      = line("$")
  let l:i                = a:tableHeadLineNum
  while l:i <= l:lastLineNum
    let l:l = getline(l:i)

    if     l:l[0] == "+"
      let l:bc   = s:defaultStr(l:l[2], "-")
      call setline(l:i, s:format(l:l, "+", a:wlals, function("s:formatBarLength",[l:bc])))
    elseif l:l[0] == "|"
      call setline(l:i, s:format(l:l, "|", a:wlals, function("s:formatWordLength")))
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
    let l:wlals            = s:wordLengthsAndAligns(l:tableHeadLineNum)
    let l:tableLastLineNum = s:formatPandocMDTable(l:tableHeadLineNum, l:wlals)
    echo "formatted line [" . l:tableHeadLineNum . "-" . l:tableLastLineNum . "]"
  endif
endfunction
