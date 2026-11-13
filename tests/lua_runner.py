import ctypes,sys
lib=ctypes.CDLL('liblua-5.4.so');lib.luaL_newstate.restype=ctypes.c_void_p;lib.luaL_openlibs.argtypes=[ctypes.c_void_p];lib.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p];lib.luaL_loadbufferx.restype=ctypes.c_int;lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p];lib.lua_pcallk.restype=ctypes.c_int;lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];lib.lua_tolstring.restype=ctypes.c_char_p
L=lib.luaL_newstate();lib.luaL_openlibs(L);b=open(sys.argv[1],'rb').read();r=lib.luaL_loadbufferx(L,b,len(b),b'@test',None)
if not r:r=lib.lua_pcallk(L,0,0,0,0,None)
if r:print('FAILED:',lib.lua_tolstring(L,-1,None).decode());raise SystemExit(1)
