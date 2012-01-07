
all: test

test: clean get build test
	luajit/src/luajit test.lua

get:
	git clone https://github.com/LuaDist/luajit

build:
	cd luajit/src; cp luaconf.h.orig luaconf.h;
	cd luajit; make

clean:
	rm -rf luajit