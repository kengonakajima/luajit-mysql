-- simple test for luajit-mysql

local mysql = require( "./luajit-mysql" ) 
local table = require( "table")
local string = require( "string")


local conn = mysql:connect( "127.0.0.1", "root", "", "luajit_mysql_test" )
print("connect:", conn )

conn:toggleLog(true)




-- blocking hello world example

local res = conn:query("DROP TABLE IF EXISTS people")
print("drop:",res)

res = conn:query( "CREATE TABLE people( name  VARCHAR(50), age INT, email CHAR(50) ) " )
print("create:",res)

data = {
   { name="Jose das Couves", age=10, email="jose@gmail.com", },
   { name="山田太郎", age=20, email="yamada@gmail.com", },
   { name= "Escape \" man", age=30, email="escaper@gmail.com", },
}

for i, p in pairs (data) do
   conn:query(string.format( "INSERT INTO people VALUES ('%s', %d, '%s')", mysql:escape(p.name), p.age, mysql:escape(p.email)) )
end


res = conn:query( "SELECT * FROM people" )
print( "select: num of rows:", #res )

for i,row in ipairs(res) do
   print( "row: ", i, row.name, row.age, row.email )
   assert( data[i].name == row.name, "expect name:" .. data[i].name .. " got:" .. row.name )
   assert( data[i].age == row.age )
   assert( data[i].email == row.email )
end


-- null test
conn:query( "DELETE FROM people" )
conn:query( "INSERT INTO people SET name=NULL, age=NULL" )

res = conn:query( "SELECT * FROM people" )
row = res[1]
assert( row )
assert( row.name == nil )
assert( row.age == nil )
assert( row.email == nil )

-- number test
conn:query( "DROP TABLE IF EXISTS ints" )
conn:query( "CREATE TABLE ints ( ti TINYINT, si SMALLINT, i INT, f FLOAT, d DOUBLE )" )
conn:query( "INSERT INTO ints SET ti=100, si=10000, i=1000000, f=1.23, d=1.23 " )
res = conn:query( "SELECT * FROM ints" )
row = res[1]
assert( row.ti == 100)
assert( row.si == 10000 )
assert( row.i == 1000000 )   
assert( row.f == 1.23)
assert( row.d == 1.23)

-- reconnect test
conn:close()

for i=1,10 do
   conn = mysql:connect( "127.0.0.1", "root", "", "luajit_mysql_test" )
   print("reconnect:", i, conn )
   conn:close()
end

conn = mysql:connect( "127.0.0.1", "root", "", "luajit_mysql_test" )
conn:toggleLog(true)

-- string and escape test
conn:query( "DROP TABLE IF EXISTS strs" )
conn:query( "CREATE TABLE strs ( s CHAR(50), vs VARCHAR(50), b BLOB, tb TINYBLOB, mb MEDIUMBLOB, lb LONGBLOB )" )
local origstr ="abc\n\r\\\'\"\0abc"  -- lua string can contain zero byte
local s = mysql:escape(origstr)
conn:query( string.format( "INSERT INTO strs SET s='%s', vs='%s', b='%s', tb='%s', mb='%s', lb='%s' ", s,s,s,s,s,s ) )
res = conn:query( "SELECT * from strs" )
row = res[1]
assert( string.len(row.s) == string.len(origstr) -4 )
assert( string.sub(row.s, 1,8) == string.sub( origstr, 1,8 ) )
assert( string.len(row.vs) == string.len(origstr) -4 )
assert( string.sub(row.vs, 1,8) == string.sub( origstr, 1,8 ) )
assert( string.len(row.b) == string.len(origstr)  )
assert( row.b == origstr )
assert( string.len(row.tb) == string.len(origstr)  )
assert( row.tb == origstr )
assert( string.len(row.mb) == string.len(origstr)  )
assert( row.mb == origstr )
assert( string.len(row.lb) == string.len(origstr)  )
assert( row.lb == origstr )

-- date test
conn:query( "DROP TABLE IF EXISTS dates" )
conn:query( "CREATE TABLE dates ( d DATE, t TIME, dt DATETIME, ts TIMESTAMP ) " )
conn:query( "INSERT INTO dates SET d='1983-09-05 13:28:00', t='1983-09-05 13:28:00', dt='1983-09-05 13:28:00', ts='1983-09-05 13:28:00' " )
res = conn:query( "SELECT * FROM dates" )
row = res[1]
assert(row)
assert(row.d)
print( "date:", row.d.year, row.d.month, row.d.day )
print( "time:", row.t.hour, row.t.min, row.t.sec )
print( "datetime:", row.dt.year, row.dt.month, row.dt.day, row.dt.hour, row.dt.min, row.dt.sec )
print( "timestamp:", row.ts.year, row.ts.month, row.ts.day, row.ts.hour, row.ts.min, row.ts.sec )
assert(row.d.year == 1983 )
assert(row.d.month == 9 )
assert(row.d.day == 5 )
assert(row.t.hour == 13 )
assert(row.t.min == 28 )
assert(row.t.sec == 00 )
assert(row.dt.year == 1983 )
assert(row.dt.month == 9 )
assert(row.dt.day == 5 )
assert(row.dt.hour == 13 )
assert(row.dt.min == 28 )
assert(row.dt.sec == 00 )
assert(row.ts.year == 1983 )
assert(row.ts.month == 9 )
assert(row.ts.day == 5 )
assert(row.ts.hour == 13 )
assert(row.ts.min == 28 )
assert(row.ts.sec == 00 )

print("test finished")

conn:close()

