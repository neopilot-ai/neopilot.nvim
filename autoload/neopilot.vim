function neopilot#build(...) abort
  let l:source = get(a:, 1, v:false)
  return join([luaeval("require('neopilot_lib').load()") ,luaeval("require('neopilot.api').build(_A)", l:source)], "\n")
endfunction
