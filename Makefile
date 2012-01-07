
all: test

test: clean get build createdb mysqltest test
	luajit/src/luajit test.lua

createdb:
	mysql -u root -P "" -e "show databases; drop database if exists luajit_mysql_test; create database luajit_mysql_test"

mysqltest:
	mysql -u root -P "" luajit_mysql_test -e "create table aho( id int ); insert into aho set id=100; insert into aho set id=1000; insert into aho set id=10000; delete from aho where id = 1000; update aho set id = 101 where id = 100; select * from aho"


get:
	git clone https://github.com/LuaDist/luajit

build:
	cd luajit/src; cp luaconf.h.orig luaconf.h;
	cd luajit; make

clean:
	rm -rf luajit