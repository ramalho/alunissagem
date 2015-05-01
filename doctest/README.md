# doctest.lua

Os arquivos deste diretório são do projeto `doctest` no LuaForge.net.

http://luaforge.net/projects/doctest/

No momento (2015-05-01), o script `doctest.lua` está quebrado: 

```
$ lua -v
Lua 5.3.0  Copyright (C) 1994-2015 Lua.org, PUC-Rio
lontra:doctest luciano$ lua doctest.lua
lua: doctest.lua:46: attempt to call a nil value (global 'module')
stack traceback:
	doctest.lua:46: in main chunk
	[C]: in ?
```
