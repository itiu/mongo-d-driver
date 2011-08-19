echo ' prepare ' $2'...'
rm $2

sed 's/#include/\/\/#include/' $1 > tmp_o

cat tmp_o > tmp_i
sed "s/const char \*cur;/char \*cur;/g" tmp_i > tmp_o

cat tmp_o > tmp_i
sed "s/( const char \* )\&node->host/node->host/g" tmp_i > tmp_o

cat tmp_o > tmp_i
sed "s/static int ( \*oid_fuzz_func )( void ) = NULL;/static int function () oid_fuzz_func = null;/g" tmp_i > tmp_o

cat tmp_o > tmp_i
sed "s/static int ( \*oid_inc_func )( void )  = NULL;/static int function () oid_inc_func = null;/g" tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define BSON_OK 0/public static byte BSON_OK = 0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define BSON_ERROR -1/public static byte BSON_ERROR= -1;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_MAJOR 0/public static byte MONGO_MAJOR = 0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_MINOR 4/public static byte MONGO_MINOR= 4;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_PATCH 0/public static byte MONGO_PATCH= 0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_OK 0/public static byte MONGO_OK= 0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_ERROR -1/public static byte MONGO_ERROR= -1;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_DEFAULT_PORT 27017/public static int MONGO_DEFAULT_PORT= 27017;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/(const char \*)b-/cast(const char \*)b-/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define MONGO_/#define MONGO_/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/ long int / long /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/ long long / long /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/scope/_scope/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/*in /*_in /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/ in / _in /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/ in->/ _in->/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/->/./g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/unsigned int/uint/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( long )/cast( long )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( bson_type )/cast( bson_type )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( mongo_message \* )/cast( mongo_message \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/(bson \*)/cast(bson \*)/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/const char \*string/const char \*_string/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( unsigned )//g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( bson_oid_t \* )/cast( bson_oid_t \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( void \* )/cast( void \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( bson \* )/cast( bson \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( mongo_reply \*\* )/cast( mongo_reply \*\* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( char \* )/cast( char \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( const char \* )/cast( const char \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( char )/cast( char )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( mongo_cursor \* )/cast( mongo_cursor \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/(const bson \*)/cast(const bson \*)/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( const mongo_md5_byte_t \* )/cast( const mongo_md5_byte_t \* )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/struct mongo_host_port \*/mongo_host_port \*/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/const char \*mongo_cursor_/char \*mongo_cursor_/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#undef/\/\/#undef/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#  define /\/\/#  define /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/const bson \*mongo_cursor_/bson \*mongo_cursor_/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/( bson_date_t )/cast( bson_date_t )/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/bson_printf_func bson_printf = printf;/alias printf bson_printf;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/bson_fprintf_func bson_fprintf = fprintf;/alias fprintf bson_fprintf;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/bson_sprintf_func bson_sprintf = sprintf;/alias sprintf bson_sprintf;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/bson_printf_func bson_errprintf = _bson_errprintf;/alias _bson_errprintf bson_errprintf;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/typedef int bson_bool_t/alias int bson_bool_t/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/typedef int64_t bson_date_t;/alias int64_t bson_date_t;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/typedef struct/struct/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/typedef union/union/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/typedef enum/enum/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/sizeof( mongo_cursor )/mongo_cursor.sizeof/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/ NULL/ null/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#ifndef/\/\/#ifndef/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#ifdef/\/\/#ifdef/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#else/\/\/#else/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#elif/\/\/#elif/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#define/\/\/#define/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#endif/\/\/#endif/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/#pragma/\/\/#pragma/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/MONGO_EXTERN_C_END/\/\/MONGO_EXTERN_C_END/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/MONGO_EXTERN_C_START/\/\/MONGO_EXTERN_C_START/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/const char \*bson_data(/char \*bson_data(/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/const char \*bson_iterator_/char \*bson_iterator_/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( \*func )( void )/( \*func )/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/FILE \*/void \*/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_err_handler func/void function ( const char \*errmsg ) func/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_err_handler set/void function ( const char \*errmsg ) set/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/static bson_err_handler err_handler/void function ( const char \*errmsg ) err_handler/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/extern /\/\/extern /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/static int ( \*oid_/\/\/static int ( \*oid_/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/void \*( \*bson_malloc_func )( size_t ) = malloc;/alias malloc bson_malloc_func;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/void \*( \*bson_realloc_func )( void \*, size_t ) = realloc;/alias realloc bson_realloc_func;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/void  ( \*bson_free )(void \*) = free;/alias free bson_free;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( mongo_reply \* )/cast( mongo_reply \* )/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/unsigned char/char/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( const char \* )string/cast( const char \* )_string/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/static const char trailingBytesForUTF8/static char trailingBytesForUTF8/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/static char \*data = \"\\005\\0\\0\\0\\0\"/static char \*data = cast(char\*)\"\\005\\0\\0\\0\\0\"/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/return cast(const char \*)b.data;/return cast(char \*)b.data;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ = ( hexbyte( str/ = cast(char)( hexbyte( str/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/{'/['/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/'}/']/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/int ( \*func )/int function () func/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/int t = time( null );/int t = cast(int) toInteger(getLocalTZA());/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/const char \*key;/char \*key;/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/case BSON_/case bson_type.BSON_/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/static int _bson_errprintf( const char /\/\/static int _bson_errprintf( const char /g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/i.cur = b.data + 4;/i.cur = cast(char\*)(b.data + 4);/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/i.cur = buffer + 4;/i.cur = cast(char*)(buffer + 4);/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/BSON_EOO;/bson_type.BSON_EOO;/g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/const char \*s = /char \*s = /g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed "s/const char \*p = /char \*p = /g" tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/char msg\[\] = \"/char* msg = cast(char*)\"/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/return i.cur + 1;/return cast (char*)(i.cur + 1);/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/const char \*t = /char \*t = /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( const bson_iterator \*i )/( bson_iterator \*i )/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( int )/cast ( int )/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/const bson_iterator \*i/bson_iterator \*i/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/iterator_type( i ) == BSON_/iterator_type( i ) == bson_type.BSON_/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_init_data( _scope, cast( void \* )( bson_iterator_value/bson_init_data( _scope, cast( char \* )( bson_iterator_value/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/return bson_iterator_date( i ) \/ 1000;/return cast(time_t)bson_iterator_date( i ) \/ 1000;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/1.5 \* ( b.dataSize + bytesNeeded );/cast(int)(1.5 \* ( b.dataSize + bytesNeeded ));/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_error_t//g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_realloc( b.data, new_size );/cast(char\*)bson_realloc( b.data, new_size );/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_validity_t//g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/b.data = 0;/b.data = null;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/b.cur = 0;/b.cur = null;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_INT,/bson_type.BSON_INT,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_LONG,/bson_type.BSON_LONG,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_DOUBLE,/bson_type.BSON_DOUBLE,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_BOOL,/bson_type.BSON_BOOL,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_NULL,/bson_type.BSON_NULL,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/BSON_UNDEFINED,/bson_type.BSON_UNDEFINED,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/\"\\0\"/cast(char\*)\"\\0\"/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_STRING/, bson_type.BSON_STRING/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_SYMBOL/, bson_type.BSON_SYMBOL/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_CODE/, bson_type.BSON_CODE/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_BINDATA/, bson_type.BSON_BINDATA/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_OID/, bson_type.BSON_OID/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_REGEX/, bson_type.BSON_REGEX/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_OBJECT/, bson_type.BSON_OBJECT/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_TIMESTAMP/, bson_type.BSON_TIMESTAMP/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_ARRAY/, bson_type.BSON_ARRAY/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, BSON_DATE/, bson_type.BSON_DATE/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/const//g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( "/( cast(char*) "/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/, "/, cast(char*) "/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/bson_err_handler old/void function (  char \*errmsg ) old/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/struct sockaddr_in sa;/sockaddr_in sa;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/( struct sockaddr \* )/cast ( sockaddr \* )/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/sizeof( sa )/sa.sizeof/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/sizeof( head )/head.sizeof/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/sizeof( fields )/fields.sizeof/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/sizeof( sa.sin_zero )/sa.sin_zero.sizeof/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/sizeof( flag )/flag.sizeof/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/\&out\./\&_out\./g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ out / _out /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ out\./ _out\./g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/\&out /\&_out /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/*out /*_out /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/!out /!_out /g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/*out,/*_out,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ out,/ _out,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ out\./ _out\./g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/ out;/ _out;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/\&out,/\&_out,/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/<out\./<_out\./g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/out = (/_out = (/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/\*out;/\*_out;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/MONGO_READ_SIZE_ERROR;/mongo_error_t.MONGO_READ_SIZE_ERROR;/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/= MONGO_CONN/= mongo_error_t.MONGO_CONN/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/r.err = 0;/r.err = cast(mongo_error_t)0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/n.err = 0;/n.err = cast(mongo_error_t)0;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/sizeof( mongo_host_port )/mongo_host_port.sizeof/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/conn.primary = bson_malloc/conn.primary = cast (mongo_host_port \*)bson_malloc/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/sizeof( mongo_replset )/mongo_replset.sizeof/g' tmp_i > tmp_o
cat tmp_o > tmp_i
sed 's/conn.replset = bson_malloc/conn.replset = cast (mongo_replset\*)bson_malloc/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/host_port = bson_malloc/host_port = cast(mongo_host_port\*)bson_malloc/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/memcpy( host_port.host + /memcpy( cast(char\*)host_port.host + /g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/err = MONGO_/err = mongo_error_t.MONGO_/g' tmp_i > tmp_o


cat tmp_o > tmp_i
sed 's/mongo_operations//g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/mongo_cursor_flags//g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/mongo_index_opts//g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/mongo_update_opts//g' tmp_i > tmp_o


cat tmp_o > tmp_i
sed 's/bson _out = {NULL, 0};/bson _out = {null, null};/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/bson _out = {NULL,0};/bson _out = {null,null};/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/strncpy( name +/strncpy( cast(char*)name +/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/\*ns = bson_malloc/\*ns = cast(char\*)bson_malloc/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/= BSON_NULL/= bson_type.BSON_NULL/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/char \*cbuf = buf;/char \*cbuf = cast(char\*)buf;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/htons( port );/htons( cast(ushort)port );/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/connect( conn.sock/connect( cast(socket_t)conn.sock/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/conn.sock = 0;/conn.sock = null;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/char \*host;/string host;/g' tmp_i > tmp_o

cat tmp_o > tmp_i
sed 's/char host\[255\];/string host;/g' tmp_i > tmp_o

cat tmp_o > $2
rm tmp_i
rm tmp_o

