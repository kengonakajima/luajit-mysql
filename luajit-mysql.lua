local ffi = require("ffi")
local table = require("table")
local string = require("string")
local math = require( "math")

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

      void mysql_close(MYSQLwrap_t *sock);

      unsigned long * mysql_fetch_lengths(MYSQL_RESwrap_t *result);

      typedef void MYSQL_TIMEwrap_t ;
      int str_to_time(const char *str,unsigned int length, MYSQL_TIMEwrap_t *l_time, int *warning);
      unsigned long long TIME_to_ulonglong_time(const MYSQL_TIMEwrap_t *);
      int str_to_datetime(const char *str, unsigned int length, MYSQL_TIMEwrap_t *l_time, unsigned int flags, int *was_cut);
      unsigned long long TIME_to_ulonglong_datetime(const MYSQL_TIMEwrap_t *);
      unsigned long long TIME_to_ulonglong_date(const MYSQL_TIMEwrap_t *);
      unsigned long long TIME_to_ulonglong_time(const MYSQL_TIMEwrap_t *);
      unsigned long long TIME_to_ulonglong(const MYSQL_TIMEwrap_t *);

]]


local clib = pcall( function() ffi.load( "libmysqlclient.dylib", true ) end ) -- for normal luajit
if not clib then
   clib = pcall( function() ffi.load( "libmysqlclient386.dylib", true ) end ) -- luvit is now built i386
end
if not clib then
   clib = pcall( function() ffi.load( "/usr/lib/libmysqlclient.so.16", true ) end ) -- for linux
end

if not clib then
   error( "cannot load libmysqlclient dynamic link library" )
end


local mysql_is_num_types =
   function(t)
      return ( t == ffi.C.MYSQL_TYPE_DECIMAL or t == ffi.C.MYSQL_TYPE_TINY or t == ffi.C.MYSQL_TYPE_SHORT or t == ffi.C.MYSQL_TYPE_LONG or t == ffi.C.MYSQL_TYPE_FLOAT or t == ffi.C.MYSQL_TYPE_DOUBLE )
   end
local mysql_is_string_types =
   function(t)
      return ( t == ffi.C.MYSQL_TYPE_STRING or t == ffi.C.MYSQL_TYPE_VAR_STRING )
   end
local mysql_is_blob_types =
   function(t)
      return ( t == ffi.C.MYSQL_TYPE_BLOB or t == ffi.C.MYSQL_TYPE_TINY_BLOB or t == ffi.C.MYSQL_TYPE_MEDIUM_BLOB or t == ffi.C.MYSQL_TYPE_LONG_BLOB )
   end


local time_ull_to_table =
   function(ffiull)  -- 19830905132800ULL 
      local n = tonumber(ffiull)
      return { sec = math.floor(n)%100,
               min = math.floor(n/100)%100,
               hour = math.floor(n/100/100)%100,
               day = math.floor(n/100/100/100)%100,
               month = math.floor(n/100/100/100/100)%100,
               year = math.floor(n/100/100/100/100/100)%10000 }
   end



local mysql_query =
   function( self, qstr )
      self:log("mysql_query:", qstr)
      ret = ffi.C.mysql_query( self.conn, qstr )
      if ret ~= 0 then
         error( "fatal:" .. ffi.string(ffi.C.mysql_error(self.mysql)))
      end
      local res = ffi.C.mysql_store_result(self.mysql)
      local nullpo = ffi.cast( "MYSQL_RESwrap_t *", 0 )
      if res == nullpo then
         return nil
      end
      local nrows = tonumber(ffi.C.mysql_num_rows( res ))
      local nfields = tonumber(ffi.C.mysql_num_fields( res ) )

      local fldtbl = {}      
      local flds = ffi.C.mysql_fetch_fields(res)
      for i=0,nfields-1 do
         local f = { name = ffi.string(flds[i].name), type = tonumber(flds[i].type) } 
         table.insert( fldtbl, f )
      end


      local restbl={}

      for i=1,nrows do
         local row = ffi.C.mysql_fetch_row( res )
         local lens = ffi.C.mysql_fetch_lengths( res )
         local rowtbl={}
         for i=1,nfields do
            local fdef = fldtbl[i]
            if row[i-1] == ffi.cast( "char*",0) then
               rowtbl[ fdef.name ] = nil
            elseif mysql_is_num_types(fdef.type) then
               rowtbl[ fdef.name ] = tonumber( ffi.string( row[i-1] ) )
            elseif mysql_is_string_types(fdef.type) then
               rowtbl[ fdef.name ] = ffi.string( row[i-1] )
            elseif mysql_is_blob_types(fdef.type) then
               rowtbl[ fdef.name ] = ffi.string( row[i-1], lens[i-1] )
            elseif fdef.type == ffi.C.MYSQL_TYPE_TIMESTAMP or fdef.type == ffi.C.MYSQL_TYPE_DATETIME or fdef.type == ffi.C.MYSQL_TYPE_DATE or fdef.type == ffi.C.MYSQL_TYPE_TIME then 
               local w = ffi.new("int[1]",{})
               local datestr = ffi.string( row[i-1] )
               local llt,r
               if fdef.type == ffi.C.MYSQL_TYPE_TIME then
                  r = ffi.C.str_to_time( datestr, string.len(datestr), self.timeStruct, w )
                  llt = ffi.C.TIME_to_ulonglong( self.timeStruct )
               else
                  r = ffi.C.str_to_datetime( datestr, string.len(datestr), self.timeStruct, 0, w )
                  if fdef.type == ffi.C.MYSQL_TYPE_DATE then
                     llt = ffi.C.TIME_to_ulonglong_date( self.timeStruct )
                     llt = llt * 100 * 100 * 100
                  elseif fdef.type == ffi.C.MYSQL_TYPE_TIMESTAMP or fdef.type == ffi.C.MYSQL_TYPE_DATETIME then
                     llt = ffi.C.TIME_to_ulonglong( self.timeStruct )
                  end
               end
               rowtbl[ fdef.name ] = time_ull_to_table(llt)
            else
               error( string.format( "type %d is not implemented", fdef.type ) )
            end
         end
         table.insert(restbl, rowtbl)         
      end

      ffi.C.mysql_free_result(res)
   
      return restbl
   end

local mysql_connect =
   function( self, host, user, password, db )
      local out={}
      local mysql = ffi.cast( "MYSQLwrap_t*",ffi.C.malloc( 1024*1024 ))
      local ret = ffi.C.mysql_init(mysql)
      self:log("mysql_init:", ret )
      local conn = ffi.C.mysql_real_connect( mysql, host, user, password, db, 3306,NULL,0 )
      local nullpo = ffi.cast( "MYSQLwrap_t*",0)
      if conn == nullpo then
         error( "fatal:" .. ffi.string(ffi.C.mysql_error(mysql)) )
         return nil
      end
      
      local timeStruct = ffi.cast( "MYSQL_TIMEwrap_t*",ffi.C.malloc(1024))
      
      out.mysql = mysql
      out.conn = conn
      out.query = mysql_query
      out.execute = mysql_query -- from luasql
      out.log = self.log
      out.doLog = false
      out.toggleLog = function(self,v) self.doLog = v end
      out.close = function(self) ffi.C.mysql_close( self.conn ) end
      out.timeStruct = timeStruct
      return out
   end      

local mysql_escape =
   function( self, orig )
      if not orig then return nil end
      local strsz = string.len(orig) * 2 + 1 + 1
      local cdata = ffi.new( "char[" .. strsz .. "]", {})
      local ret = ffi.C.mysql_escape_string(cdata, orig, string.len(orig) )
      return ffi.string( cdata, ret )      
   end

local _log = function(self,...) if self.doLog then print(...) end end

--selfTest()

return {
   connect = mysql_connect,
   escape = mysql_escape,
   log = _log,
   doLog = false
}