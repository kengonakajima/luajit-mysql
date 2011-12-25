local ffi = require("ffi")

ffi.cdef[[
      typedef void MYSQLwrap_t;
      void free(void*ptr);
      void * malloc(size_t size);
      unsigned long	mysql_escape_string(char *to,const char *from, unsigned long from_length);

      MYSQLwrap_t * mysql_init( MYSQLwrap_t *mysql );

      MYSQLwrap_t * mysql_real_connect( MYSQLwrap_t *mysql,
                                        const char *host,
                                        const char *user,
                                        const char *passwd,
                                        const char *db,
                                        unsigned int port,
                                        const char *unix_socket,
                                        unsigned long clientflag);

      unsigned int mysql_errno(MYSQLwrap_t *mysql);
      const char *mysql_error(MYSQLwrap_t *mysql);

      int  mysql_query(MYSQLwrap_t *mysql, const char *q);
      typedef void MYSQL_RESwrap_t;
      MYSQL_RESwrap_t * mysql_store_result(MYSQLwrap_t *mysql);

      unsigned long long mysql_num_rows(MYSQL_RESwrap_t *res);

      typedef char **MYSQL_ROWwrap_t;		

      MYSQL_ROWwrap_t mysql_fetch_row(MYSQL_RESwrap_t *result);

      void mysql_free_result(MYSQL_RESwrap_t *result);

      enum enum_field_types { MYSQL_TYPE_DECIMAL, MYSQL_TYPE_TINY,
                              MYSQL_TYPE_SHORT,  MYSQL_TYPE_LONG,
                              MYSQL_TYPE_FLOAT,  MYSQL_TYPE_DOUBLE,
                              MYSQL_TYPE_NULL,   MYSQL_TYPE_TIMESTAMP,
                              MYSQL_TYPE_LONGLONG,MYSQL_TYPE_INT24,
                              MYSQL_TYPE_DATE,   MYSQL_TYPE_TIME,
                              MYSQL_TYPE_DATETIME, MYSQL_TYPE_YEAR,
                              MYSQL_TYPE_NEWDATE, MYSQL_TYPE_VARCHAR,
                              MYSQL_TYPE_BIT,
                              MYSQL_TYPE_NEWDECIMAL=246,
                              MYSQL_TYPE_ENUM=247,
                              MYSQL_TYPE_SET=248,
                              MYSQL_TYPE_TINY_BLOB=249,
                              MYSQL_TYPE_MEDIUM_BLOB=250,
                              MYSQL_TYPE_LONG_BLOB=251,
                              MYSQL_TYPE_BLOB=252,
                              MYSQL_TYPE_VAR_STRING=253,
                              MYSQL_TYPE_STRING=254,
                              MYSQL_TYPE_GEOMETRY=255

                           };


      // mysql 5.1.x
      typedef struct st_mysql_field {
         char *name;                 /* Name of column */
         char *org_name;             /* Original column name, if an alias */
         char *table;                /* Table of column if column was a field */
         char *org_table;            /* Org table name, if table was an alias */
         char *db;                   /* Database for table */
         char *catalog;	      /* Catalog for table */
         char *def;                  /* Default value (set by mysql_list_fields) */
         unsigned long length;       /* Width of column (create length) */
         unsigned long max_length;   /* Max width for selected set */
         unsigned int name_length;
         unsigned int org_name_length;
         unsigned int table_length;
         unsigned int org_table_length;
         unsigned int db_length;
         unsigned int catalog_length;
         unsigned int def_length;
         unsigned int flags;         /* Div flags */
         unsigned int decimals;      /* Number of decimals in field */
         unsigned int charsetnr;     /* Character set */
         int type;                   /* Type of field. See mysql_com.h for types */
         void *extension;
      } MYSQL_FIELDwrap_t;

      MYSQL_FIELDwrap_t * mysql_fetch_fields(MYSQL_RESwrap_t *res);

      unsigned int mysql_num_fields(MYSQL_RESwrap_t *res);

]]

local printLog = false
local log = function(...) if printLog then print(...) end end


local clib = ffi.load( "libmysqlclient.dylib", true )                       


local mysql = ffi.cast( "MYSQLwrap_t*",ffi.C.malloc( 1024*1024 )) -- arbitrary bigger size
log("mysql malloc:",mysql)

local ret = ffi.C.mysql_init(mysql)
log("mysql_init:", ret )

local conn = ffi.C.mysql_real_connect( mysql, "127.0.0.1", "mysql", "", "test", 3306,NULL,0 )
local nullpo = ffi.cast( "MYSQLwrap_t*",0)

if conn == nullpo then
   local err = ffi.string(ffi.C.mysql_error(mysql))
   print("mysql_real_connect: err:", err )
   error("fatal")
end

log("mysql_real_connect conn:", conn )

function doall()
   local ret = ffi.C.mysql_query( conn, "drop table if exists people" )
   assert(ret==0)
   log("mysql_query drop: ", ret )

   ret = ffi.C.mysql_query( conn, "create table people ( name char(100), age int, email char(100) )" )
   log("mysql_query create: ", ret )
   assert(ret==0)


   ret = ffi.C.mysql_query( conn, "insert into people set name='yamada', age=3, email='yamada@gmail.com' " )
   log("mysql_query insert: ", ret )
   if ret ~= 0 then
      log( ffi.string(ffi.C.mysql_error(mysql) ))
      error("fatal")
   end

   ret = ffi.C.mysql_query( conn, "insert into people set name='satou', age=10, email='satou@gmail.com' " )
   log("mysql_query insert: ", ret )
   if ret ~= 0 then
      log( ffi.string(ffi.C.mysql_error(mysql) ))   
      error("fatal")
   end


   ret = ffi.C.mysql_query( conn, "select name, age, email from people" )
   log("mysql_query select:", ret )
   if ret ~= 0 then
      log( ffi.string(ffi.C.mysql_error(mysql) ))   
      error("fatal")
   end

   local res = ffi.C.mysql_store_result(mysql)
   log("mysql_store_result:",res)

   nullpo = ffi.cast( "MYSQL_RESwrap_t *", 0 )
   if res == nullpo then
      log( ffi.string(ffi.C.mysql_error(mysql) ))      
      error("store_result must success")
   end

   local nrows = tonumber(ffi.C.mysql_num_rows( res ))
   log( "mysql_num_rows:", nrows )
   if nrows ~= 2 then
      log( ffi.string(ffi.C.mysql_error(mysql) ))      
      error("numrows must be 2")
   end

   local nfields = tonumber(ffi.C.mysql_num_fields( res ) )
   log("mysql_num_fields:", nfields)
   if nfields ~= 3 then
      log( ffi.string(ffi.C.mysql_error(mysql) ))      
      error("numfields must be 3")
   end

   local fldtbl = {}
   
   local flds = ffi.C.mysql_fetch_fields(res)
   log("mysql_fetch_fields:", flds )   
   for i=0,nfields-1 do
      local f = { name = ffi.string(flds[i].name), type = tonumber(flds[i].type) } 
      table.insert( fldtbl, f )
--      log( "name:", f.name, "type:", f.type )
   end

   local restbl={}
   for i=1,nrows do
      local row = ffi.C.mysql_fetch_row( res )

      log( "fetch loop:", i, " name:", ffi.string(row[0] ), " age:", tonumber(ffi.string(row[1]) ), " email:", ffi.string(row[2]) )
      
      local rowtbl={}
      for i=1,nfields do
         local fdef = fldtbl[i]
         if fdef.type == ffi.C.MYSQL_TYPE_LONG then
            rowtbl[ fdef.name ] = tonumber( ffi.string( row[i-1] ) )
         elseif fdef.type == ffi.C.MYSQL_TYPE_STRING then
            rowtbl[ fdef.name ] = ffi.string( row[i-1] )
         else
            error( string.format( "type %d is not implemented", fdef.type ) )
         end
      end
      table.insert(restbl, rowtbl)
   end

   for i,v in ipairs(restbl) do
      print("restbl loop:", i, v.name, v.age, v.email )
   end

   ffi.C.mysql_free_result(res)

end

local N=100
local st = os.clock()
for i=1,N do
   doall()
end
local et = os.clock()
print( "time:",(et-st), " avg:", N/(et-st), " q/CPUsec" )