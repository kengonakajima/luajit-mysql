-- simple test for luajit-mysql

local mysql = require( "luajit-mysql" )

local conn = mysql:connect( "127.0.0.1", "mysql", "", "test" )
print("connect:", conn )

local res = conn:query("DROP TABLE if exists people")
print("drop:",res)

res = conn:query( "CREATE TABLE people( name  varchar(50), age int, email varchar(50) ) " )
print("create:",res)

data = {
   { name="Jose das Couves", age=10, email="jose@couves.com", },
   { name="山田太郎", age=20, email="yamada@cafundo.com", },
   { name= "Escape \" man", age=30, email="maria@dores.com", },
}

for i, p in pairs (data) do
   res = conn:query(string.format( "INSERT INTO people VALUES ('%s', %d, '%s')", mysql:escape(p.name), p.age, mysql:escape(p.email)) )
end

res = conn:query( "select * from people" )
print( "select: num of rows:", #res )

for i,row in ipairs(res) do
   print( "row: ", i, row.name, row.age, row.email )
   assert( data[i].name == row.name, "expect name:" .. data[i].name .. " got:" .. row.name )
   assert( data[i].age == row.age )
   assert( data[i].email == row.email )
end

conn:close()

