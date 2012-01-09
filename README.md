MySQL binding for LuaJIT with FFI
====
<a href="http://travis-ci.org/kengonakajima/luajit-mysql"><img src="https://secure.travis-ci.org/kengonakajima/luajit-mysql.png"></a>


Using FFI, pure Lua. so you don't have to build when install. 
(still requires libmysqlclient dynamic link object in environment)


How to Use
====
See test.lua that includes hello world examples and tests on variable types.


Requirements
====
 - OSX: libmysqlclient.dylib (tested on mysql 5.1.59)
 - Linux: (not tested yet)

Limitations
====
Only supports blocking interface (libmysqlclient)



TODO
====
 - linux test
 - async : Tough. need to modify luvit, libuv 
