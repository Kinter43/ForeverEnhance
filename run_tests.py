"""Run the addon regression suite using a local Lua shared library.

No WoW client is needed for these mocked API tests. They do not replace an
in-client smoke test. Lua 5.1-compatible addon syntax is also checked here.
"""
import ctypes
import ctypes.util
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
os.chdir(root)
library_names = ['lua5.1', 'lua5.4', 'lua5.3', 'lua-5.1', 'lua-5.4', 'lua-5.3']
name = next((ctypes.util.find_library(x) for x in library_names if ctypes.util.find_library(x)), None)
if not name:
    raise SystemExit('Install a Lua 5.1, 5.3, or 5.4 shared library to run tests.')
lib = ctypes.CDLL(name)
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.lua_close.argtypes = [ctypes.c_void_p]
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype = ctypes.c_char_p
state = lib.luaL_newstate()
lib.luaL_openlibs(state)
try:
    if hasattr(lib, 'luaL_loadfilex'):
        lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
        status = lib.luaL_loadfilex(state, b'dev/Tests.lua', None)
    else:
        lib.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        status = lib.luaL_loadfile(state, b'dev/Tests.lua')
    if not status:
        if hasattr(lib, 'lua_pcallk'):
            lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p]
            status = lib.lua_pcallk(state, 0, -1, 0, 0, None)
        else:
            lib.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
            status = lib.lua_pcall(state, 0, -1, 0)
    if status:
        raise SystemExit(lib.lua_tolstring(state, -1, None).decode())
finally:
    lib.lua_close(state)
