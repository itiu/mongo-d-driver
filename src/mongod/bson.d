module mongod.bson;

private import std.c.stdlib;
private import std.c.string;
private import std.datetime;
private import std.c.stdio;
private import std.stdarg;

private import mongod.bson_h;
private import mongod.numbers;

// ++ stringz . string

static int _bson_append_string(bson* b, string name, string value)
{
	return _bson_append_string_base(b, name, value, bson_type.BSON_STRING);
}

static int _bson_append_string_base(bson* b, string name, string value, bson_type type)
{
	int sl = value.length + 1;
	if(bson_check_string(b, cast(char*) value, sl - 1) == BSON_ERROR)
		return BSON_ERROR;
	if(_bson_append_estart(b, type, name, 4 + sl) == BSON_ERROR)
	{
		return BSON_ERROR;
	}
	bson_append32(b, &sl);
	bson_append(b, cast(char*) value, sl - 1);
	bson_append_byte(b, cast(char) 0);
	return BSON_OK;
}

static int _bson_append_estart(bson* b, int type, string name, int dataSize)
{
	if(name is null)
		return BSON_ERROR;

	int len = name.length + 1;
	if(bson_ensure_space(b, 1 + len + dataSize) == BSON_ERROR)
	{
		return BSON_ERROR;
	}

	if(bson_check_field_name(b, cast(char*) name, len - 1) == BSON_ERROR)
	{
		bson_builder_error(b);
		return BSON_ERROR;
	}

	bson_append_byte(b, cast(char) type);
	bson_append(b, cast(char*) name, len - 1);
	bson_append_byte(b, cast(char) 0);
	return BSON_OK;
}

static int _bson_append_start_array(bson* b, string name)
{
	if(_bson_append_estart(b, bson_type.BSON_ARRAY, name, 5) == BSON_ERROR)
		return BSON_ERROR;
	b.stack[b.stackPos++] = b.cur - b.data;
	bson_append32(b, &zero);
	return BSON_OK;
}

static int _bson_append_int(bson* b, string name,  int i)
{
	if(_bson_append_estart(b, bson_type.BSON_INT, name, 4) == BSON_ERROR)
		return BSON_ERROR;
	bson_append32(b, &i);
	return BSON_OK;
}

static int _bson_append_start_object(bson* b, string name)
{
	if(_bson_append_estart(b, bson_type.BSON_OBJECT, name, 5) == BSON_ERROR)
		return BSON_ERROR;
	b.stack[b.stackPos++] = b.cur - b.data;
	bson_append32(b, &zero);
	return BSON_OK;
}

static int _bson_append_regex(bson* b, string name, string pattern, string opts)
{
	int plen = 1;
	if(pattern !is null)
		plen = pattern.length + 1;

	int olen = 1;
	if(opts !is null)
		olen = opts.length + 1;

	if(_bson_append_estart(b, bson_type.BSON_REGEX, name, plen + olen) == BSON_ERROR)
		return BSON_ERROR;

	if(bson_check_string(b, cast(char*) pattern, plen - 1) == BSON_ERROR)
		return BSON_ERROR;

	bson_append(b, cast(char*) pattern, plen - 1);
	bson_append_byte(b, cast(char) 0);
	bson_append(b, cast(char*) opts, olen - 1);
	bson_append_byte(b, cast(char) 0);

	return BSON_OK;
}

version(MONGO_BIG_ENDIAN)
{
//	//#define bson_little_endian64(out, in) ( bson_swap_endian64(out, in) )
//	//#define bson_little_endian32(out, in) ( bson_swap_endian32(out, in) )

//	//#define bson_big_endian32(out, in) ( memcpy(out, in, 4) )
} else
{
	////#else

	////#define bson_little_endian64(out, in) ( memcpy(out, in, 8) )
	static void bson_little_endian64(void* outp,  void* inp)
	{
		memcpy(outp, inp, 8);
	}

	////#define bson_little_endian32(out, in) ( memcpy(out, in, 4) )
	static void bson_little_endian32(void* outp,  void* inp)
	{
		memcpy(outp, inp, 4);
	}

	////#define bson_big_endian32(out, in) ( bson_swap_endian32(out, in) )
	static void bson_big_endian32(void* outp, void* inp)
	{
		bson_swap_endian32(cast(char*) outp, cast(char*) inp);
	}

	////#define bson_big_endian64(out, in) ( bson_swap_endian64(out, in) )
	static void bson_big_endian64(void* outp, void* inp)
	{
		bson_swap_endian64(cast(char*) outp, cast(char*) inp);
	}
//	//#endif
}

static void bson_swap_endian64(char* outp, char* inp)
{
	outp[0] = inp[7];
	outp[1] = inp[6];
	outp[2] = inp[5];
	outp[3] = inp[4];
	outp[4] = inp[3];
	outp[5] = inp[2];
	outp[6] = inp[1];
	outp[7] = inp[0];

}

static void bson_swap_endian32(char* outp, char* inp)
{
	outp[0] = inp[3];
	outp[1] = inp[2];
	outp[2] = inp[1];
	outp[3] = inp[0];
}


/* bson.c */

/*    Copyright 2009, 2010 10gen Inc.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except _in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to _in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

//#include <stdlib.h>
//#include <string.h>
//#include <stdio.h>
//#include <time.h>
//#include <limits.h>

//#include "bson.h"
//#include "encoding.h"

 int initialBufferSize = 128;

/* only need one of these */
static  int zero = 0;

/* Custom standard function pointers. */
alias malloc bson_malloc_func;
alias realloc bson_realloc_func;
alias free bson_free;
alias printf bson_printf;
alias fprintf bson_fprintf;
alias sprintf bson_sprintf;

//static int _bson_errprintf(  char *, ... );
alias _bson_errprintf bson_errprintf;

/* ObjectId fuzz functions. */
static int function () oid_fuzz_func = null;
static int function () oid_inc_func = null;

/* ----------------------------
   READING
   ------------------------------ */

bson *bson_empty( bson *obj ) {
    static char *data = cast(char*)"\005\0\0\0\0";
    bson_init_data( obj, data );
    obj.finished = 1;
    obj.err = 0;
    obj.stackPos = 0;
    return obj;
}

void bson_copy_basic( bson *_out,  bson *_in ) {
    if ( !_out ) return;
    bson_init_size( _out, bson_size( _in ) );
    memcpy( _out.data, _in.data, bson_size( _in ) );
}

void bson_copy( bson *_out,  bson *_in ) {
    int i;

    if ( !_out ) return;
    bson_copy_basic( _out, _in );
    _out.cur = _out.data + ( _in.cur - _in.data );
    _out.dataSize = _in.dataSize;
    _out.finished = _in.finished;
    _out.stackPos = _in.stackPos;
    _out.err = _in.err;
    for( i=0; i<_out.stackPos; i++ )
        _out.stack[i] = _in.stack[i];
}

int bson_init_data( bson *b, char *data ) {
    b.data = data;
    return BSON_OK;
}

static void _bson_reset( bson *b ) {
    b.finished = 0;
    b.stackPos = 0;
    b.err = 0;
    b.errstr = null;
}

int bson_size(  bson *b ) {
    int i;
    if ( ! b || ! b.data )
        return 0;
    bson_little_endian32( &i, b.data );
    return i;
}

char *bson_data( bson *b ) {
    return cast(char *)b.data;
}

static char hexbyte( char hex ) {
    switch ( hex ) {
    case '0':
        return 0x0;
    case '1':
        return 0x1;
    case '2':
        return 0x2;
    case '3':
        return 0x3;
    case '4':
        return 0x4;
    case '5':
        return 0x5;
    case '6':
        return 0x6;
    case '7':
        return 0x7;
    case '8':
        return 0x8;
    case '9':
        return 0x9;
    case 'a':
    case 'A':
        return 0xa;
    case 'b':
    case 'B':
        return 0xb;
    case 'c':
    case 'C':
        return 0xc;
    case 'd':
    case 'D':
        return 0xd;
    case 'e':
    case 'E':
        return 0xe;
    case 'f':
    case 'F':
        return 0xf;
    default:
        return 0x0; /* something smarter? */
    }
}

void bson_oid_from_string( bson_oid_t *oid,  char *str ) {
    int i;
    for ( i=0; i<12; i++ ) {
        oid.bytes[i] = cast(char)( hexbyte( str[2*i] ) << 4 ) | hexbyte( str[2*i + 1] );
    }
}

void bson_oid_to_string(  bson_oid_t *oid, char *str ) {
    static  char hex[16] = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
    int i;
    for ( i=0; i<12; i++ ) {
        str[2*i]     = hex[( oid.bytes[i] & 0xf0 ) >> 4];
        str[2*i + 1] = hex[ oid.bytes[i] & 0x0f      ];
    }
    str[24] = '\0';
}

void bson_set_oid_fuzz( int function () func ) {
    oid_fuzz_func = func;
}

void bson_set_oid_inc( int function () func ) {
    oid_inc_func = func;
}

void bson_oid_gen( bson_oid_t *oid ) {
    static int incr = 0;
    static int fuzz = 0;
    int i;
    
    auto currentTime = Clock.currTime();

    time_t t = currentTime.toUnixTime(); 

    if( oid_inc_func )
        i = oid_inc_func();
    else
        i = incr++;

    if ( !fuzz ) {
        if ( oid_fuzz_func )
            fuzz = oid_fuzz_func();
        else {
            srand( t );
            fuzz = rand();
        }
    }

    bson_big_endian32( &oid.ints[0], &t );
    oid.ints[1] = fuzz;
    bson_big_endian32( &oid.ints[2], &i );
}

time_t bson_oid_generated_time( bson_oid_t *oid ) {
    time_t _out;
    bson_big_endian32( &_out, &oid.ints[0] );

    return _out;
}

void bson_print( bson *b ) {
    bson_print_raw( b.data , 0 );
}

void bson_print_raw(  char *data , int depth ) {
    bson_iterator i;
    char *key;
    int temp;
    bson_timestamp_t ts;
    char oidhex[25];
    bson _scope;
    bson_iterator_from_buffer( &i, data );

    while ( bson_iterator_next( &i ) ) {
        bson_type t = bson_iterator_type( &i );
        if ( t == 0 )
            break;
        key = bson_iterator_key( &i );

        for ( temp=0; temp<=depth; temp++ )
            printf( cast(char*) "\t" );
        bson_printf( cast(char*) "%s : %d \t " , key , t );
        switch ( t ) {
        case bson_type.BSON_DOUBLE:
            printf( cast(char*) "%f" , bson_iterator_double( &i ) );
            break;
        case bson_type.BSON_STRING:
            printf( cast(char*) "%s" , bson_iterator_string( &i ) );
            break;
        case bson_type.BSON_SYMBOL:
            printf( cast(char*) "SYMBOL: %s" , bson_iterator_string( &i ) );
            break;
        case bson_type.BSON_OID:
            bson_oid_to_string( bson_iterator_oid( &i ), oidhex );
            printf( cast(char*) "%s" , oidhex );
            break;
        case bson_type.BSON_BOOL:
            printf( cast(char*) "%s" , bson_iterator_bool( &i ) ? "true" : "false" );
            break;
        case bson_type.BSON_DATE:
            printf( cast(char*) "%ld" , cast( long )bson_iterator_date( &i ) );
            break;
        case bson_type.BSON_BINDATA:
            printf( cast(char*) "BSON_BINDATA" );
            break;
        case bson_type.BSON_UNDEFINED:
            printf( cast(char*) "BSON_UNDEFINED" );
            break;
        case bson_type.BSON_NULL:
            printf( cast(char*) "BSON_NULL" );
            break;
        case bson_type.BSON_REGEX:
            printf( cast(char*) "BSON_REGEX: %s", bson_iterator_regex( &i ) );
            break;
        case bson_type.BSON_CODE:
            printf( cast(char*) "BSON_CODE: %s", bson_iterator_code( &i ) );
            break;
        case bson_type.BSON_CODEWSCOPE:
            printf( cast(char*) "BSON_CODE_W_SCOPE: %s", bson_iterator_code( &i ) );
            bson_init( &_scope );
            bson_iterator_code__scope( &i, &_scope );
            printf( cast(char*) "\n\t SCOPE: " );
            bson_print( &_scope );
            break;
        case bson_type.BSON_INT:
            printf( cast(char*) "%d" , bson_iterator_int( &i ) );
            break;
        case bson_type.BSON_LONG:
            printf( cast(char*) "%lld" , cast( long )bson_iterator_long( &i ) );
            break;
        case bson_type.BSON_TIMESTAMP:
            ts = bson_iterator_timestamp( &i );
            printf( cast(char*) "i: %d, t: %d", ts.i, ts.t );
            break;
        case bson_type.BSON_OBJECT:
        case bson_type.BSON_ARRAY:
            printf( cast(char*) "\n" );
            bson_print_raw( bson_iterator_value( &i ) , depth + 1 );
            break;
        default:
            bson_errprintf( cast(char*) "can't print type : %d\n" , t );
        }
        printf( cast(char*) "\n" );
    }
}

/* ----------------------------
   ITERATOR
   ------------------------------ */

void bson_iterator_init( bson_iterator *i,  bson *b ) {
    i.cur = cast(char*)(b.data + 4);
    i.first = 1;
}

void bson_iterator_from_buffer( bson_iterator *i,  char *buffer ) {
    i.cur = cast(char*)(buffer + 4);
    i.first = 1;
}

bson_type bson_find( bson_iterator *it,  bson *obj,  char *name ) {
    bson_iterator_init( it, cast(bson *)obj );
    while( bson_iterator_next( it ) ) {
        if ( strcmp( name, bson_iterator_key( it ) ) == 0 )
            break;
    }
    return bson_iterator_type( it );
}

bson_bool_t bson_iterator_more( bson_iterator *i ) {
    return *( i.cur );
}

bson_type bson_iterator_next( bson_iterator *i ) {
    int ds;

    if ( i.first ) {
        i.first = 0;
        return cast( bson_type )( *i.cur );
    }

    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_EOO:
        return bson_type.BSON_EOO; /* don't advance */
    case bson_type.BSON_UNDEFINED:
    case bson_type.BSON_NULL:
        ds = 0;
        break;
    case bson_type.BSON_BOOL:
        ds = 1;
        break;
    case bson_type.BSON_INT:
        ds = 4;
        break;
    case bson_type.BSON_LONG:
    case bson_type.BSON_DOUBLE:
    case bson_type.BSON_TIMESTAMP:
    case bson_type.BSON_DATE:
        ds = 8;
        break;
    case bson_type.BSON_OID:
        ds = 12;
        break;
    case bson_type.BSON_STRING:
    case bson_type.BSON_SYMBOL:
    case bson_type.BSON_CODE:
        ds = 4 + bson_iterator_int_raw( i );
        break;
    case bson_type.BSON_BINDATA:
        ds = 5 + bson_iterator_int_raw( i );
        break;
    case bson_type.BSON_OBJECT:
    case bson_type.BSON_ARRAY:
    case bson_type.BSON_CODEWSCOPE:
        ds = bson_iterator_int_raw( i );
        break;
    case bson_type.BSON_DBREF:
        ds = 4+12 + bson_iterator_int_raw( i );
        break;
    case bson_type.BSON_REGEX: {
        char *s = bson_iterator_value( i );
        char *p = s;
        p += strlen( p )+1;
        p += strlen( p )+1;
        ds = p-s;
        break;
    }

    default: {
        char* msg = cast(char*)"unknown type: 000000000000";
        bson_numstr( msg+14, ( i.cur[0] ) );
        bson_fatal_msg( 0, msg );
        return bson_type.BSON_EOO;
    }
    }

    i.cur += 1 + strlen( i.cur + 1 ) + 1 + ds;

    return cast( bson_type )( *i.cur );
}

bson_type bson_iterator_type( bson_iterator *i ) {
    return cast( bson_type )i.cur[0];
}

char *bson_iterator_key( bson_iterator *i ) {
    return cast (char*)(i.cur + 1);
}

char *bson_iterator_value( bson_iterator *i ) {
    char *t = i.cur + 1;
    t += strlen( t ) + 1;
    return t;
}

/* types */

int bson_iterator_int_raw( bson_iterator *i ) {
    int _out;
    bson_little_endian32( &_out, bson_iterator_value( i ) );
    return _out;
}

double bson_iterator_double_raw( bson_iterator *i ) {
    double _out;
    bson_little_endian64( &_out, bson_iterator_value( i ) );
    return _out;
}

int64_t bson_iterator_long_raw( bson_iterator *i ) {
    int64_t _out;
    bson_little_endian64( &_out, bson_iterator_value( i ) );
    return _out;
}

bson_bool_t bson_iterator_bool_raw( bson_iterator *i ) {
    return bson_iterator_value( i )[0];
}

bson_oid_t *bson_iterator_oid( bson_iterator *i ) {
    return cast( bson_oid_t * )bson_iterator_value( i );
}

int bson_iterator_int( bson_iterator *i ) {
    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_INT:
        return bson_iterator_int_raw( i );
    case bson_type.BSON_LONG:
        return cast ( int )bson_iterator_long_raw( i );
    case bson_type.BSON_DOUBLE:
        return cast ( int )bson_iterator_double_raw( i );
    default:
        return 0;
    }
}

double bson_iterator_double( bson_iterator *i ) {
    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_INT:
        return bson_iterator_int_raw( i );
    case bson_type.BSON_LONG:
        return bson_iterator_long_raw( i );
    case bson_type.BSON_DOUBLE:
        return bson_iterator_double_raw( i );
    default:
        return 0;
    }
}

int64_t bson_iterator_long( bson_iterator *i ) {
    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_INT:
        return bson_iterator_int_raw( i );
    case bson_type.BSON_LONG:
        return bson_iterator_long_raw( i );
    case bson_type.BSON_DOUBLE:
        return cast (int64_t) bson_iterator_double_raw( i );
    default:
        return 0;
    }
}

bson_timestamp_t bson_iterator_timestamp( bson_iterator *i ) {
    bson_timestamp_t ts;
    bson_little_endian32( &( ts.i ), bson_iterator_value( i ) );
    bson_little_endian32( &( ts.t ), bson_iterator_value( i ) + 4 );
    return ts;
}

bson_bool_t bson_iterator_bool( bson_iterator *i ) {
    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_BOOL:
        return bson_iterator_bool_raw( i );
    case bson_type.BSON_INT:
        return bson_iterator_int_raw( i ) != 0;
    case bson_type.BSON_LONG:
        return bson_iterator_long_raw( i ) != 0;
    case bson_type.BSON_DOUBLE:
        return bson_iterator_double_raw( i ) != 0;
    case bson_type.BSON_EOO:
    case bson_type.BSON_NULL:
        return 0;
    default:
        return 1;
    }
}

char *bson_iterator_string( bson_iterator *i ) {
    return bson_iterator_value( i ) + 4;
}

int bson_iterator_string_len( bson_iterator *i ) {
    return bson_iterator_int_raw( i );
}

char *bson_iterator_code( bson_iterator *i ) {
    switch ( bson_iterator_type( i ) ) {
    case bson_type.BSON_STRING:
    case bson_type.BSON_CODE:
        return bson_iterator_value( i ) + 4;
    case bson_type.BSON_CODEWSCOPE:
        return bson_iterator_value( i ) + 8;
    default:
        return null;
    }
}

void bson_iterator_code__scope( bson_iterator *i, bson *_scope ) {
    if ( bson_iterator_type( i ) == bson_type.BSON_CODEWSCOPE ) {
        int code_len;
        bson_little_endian32( &code_len, bson_iterator_value( i )+4 );
        bson_init_data( _scope, cast( char * )( bson_iterator_value( i )+8+code_len ) );
    } else {
        bson_empty( _scope );
    }
}

bson_date_t bson_iterator_date( bson_iterator *i ) {
    return bson_iterator_long_raw( i );
}

time_t bson_iterator_time_t( bson_iterator *i ) {
    return cast(time_t)bson_iterator_date( i ) / 1000;
}

int bson_iterator_bin_len( bson_iterator *i ) {
    return ( bson_iterator_bin_type( i ) == BSON_BIN_BINARY_OLD )
           ? bson_iterator_int_raw( i ) - 4
           : bson_iterator_int_raw( i );
}

char bson_iterator_bin_type( bson_iterator *i ) {
    return bson_iterator_value( i )[4];
}

char *bson_iterator_bin_data( bson_iterator *i ) {
    return ( bson_iterator_bin_type( i ) == BSON_BIN_BINARY_OLD )
           ? bson_iterator_value( i ) + 9
           : bson_iterator_value( i ) + 5;
}

char *bson_iterator_regex( bson_iterator *i ) {
    return bson_iterator_value( i );
}

char *bson_iterator_regex_opts( bson_iterator *i ) {
    char *p = bson_iterator_value( i );
    return p + strlen( p ) + 1;

}

void bson_iterator_subobject( bson_iterator *i, bson *sub ) {
    bson_init_data( sub, cast( char * )bson_iterator_value( i ) );
    _bson_reset( sub );
    sub.finished = 1;
}

void bson_iterator_subiterator( bson_iterator *i, bson_iterator *sub ) {
    bson_iterator_from_buffer( sub, bson_iterator_value( i ) );
}

/* ----------------------------
   BUILDING
   ------------------------------ */

static void _bson_init_size( bson *b, int size ) {
    if( size == 0 )
        b.data = null;
    else
        b.data = cast( char * )bson_malloc( size );
    b.dataSize = size;
    b.cur = b.data + 4;
    _bson_reset( b );
}

void bson_init( bson *b ) {
    _bson_init_size( b, initialBufferSize );
}

void bson_init_size( bson *b, int size ) {
    _bson_init_size( b, size );
}

void bson_append_byte( bson *b, char c ) {
    b.cur[0] = c;
    b.cur++;
}

void bson_append( bson *b,  void *data, int len ) {
    memcpy( b.cur , data , len );
    b.cur += len;
}

void bson_append32( bson *b,  void *data ) {
    bson_little_endian32( b.cur, data );
    b.cur += 4;
}

void bson_append64( bson *b,  void *data ) {
    bson_little_endian64( b.cur, data );
    b.cur += 8;
}

int bson_ensure_space( bson *b,  int bytesNeeded ) {
    int pos = b.cur - b.data;
    char *orig = b.data;
    int new_size;

    if ( pos + bytesNeeded <= b.dataSize )
        return BSON_OK;

    new_size = cast(int)(1.5 * ( b.dataSize + bytesNeeded ));

    if( new_size < b.dataSize ) {
        if( ( b.dataSize + bytesNeeded ) < INT_MAX )
            new_size = INT_MAX;
        else {
            b.err = BSON_SIZE_OVERFLOW;
            return BSON_ERROR;
        }
    }

    b.data = cast(char*)bson_realloc( b.data, new_size );
    if ( !b.data )
        bson_fatal_msg( !!b.data, cast(char*) "realloc() failed" );

    b.dataSize = new_size;
    b.cur += b.data - orig;

    return BSON_OK;
}

int bson_finish( bson *b ) {
    int i;

    if( b.err & BSON_NOT_UTF8 )
        return BSON_ERROR;

    if ( ! b.finished ) {
        if ( bson_ensure_space( b, 1 ) == BSON_ERROR ) return BSON_ERROR;
        bson_append_byte( b, 0 );
        i = b.cur - b.data;
        bson_little_endian32( b.data, &i );
        b.finished = 1;
    }

    return BSON_OK;
}

void bson_destroy( bson *b ) {
    bson_free( b.data );
    b.err = 0;
    b.data = null;
    b.cur = null;
    b.finished = 1;
}

static int bson_append_estart( bson *b, int type,  char *name,  int dataSize ) {
     int len = strlen( name ) + 1;

    if ( b.finished ) {
        b.err |= BSON_ALREADY_FINISHED;
        return BSON_ERROR;
    }

    if ( bson_ensure_space( b, 1 + len + dataSize ) == BSON_ERROR ) {
        return BSON_ERROR;
    }

    if( bson_check_field_name( b, cast(  char * )name, len - 1 ) == BSON_ERROR ) {
        bson_builder_error( b );
        return BSON_ERROR;
    }

    bson_append_byte( b, cast( char )type );
    bson_append( b, name, len );
    return BSON_OK;
}

/* ----------------------------
   BUILDING TYPES
   ------------------------------ */

int bson_append_int( bson *b,  char *name,  int i ) {
    if ( bson_append_estart( b, bson_type.BSON_INT, name, 4 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append32( b , &i );
    return BSON_OK;
}

int bson_append_long( bson *b,  char *name,  int64_t i ) {
    if ( bson_append_estart( b , bson_type.BSON_LONG, name, 8 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append64( b , &i );
    return BSON_OK;
}

int bson_append_double( bson *b,  char *name,  double d ) {
    if ( bson_append_estart( b, bson_type.BSON_DOUBLE, name, 8 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append64( b , &d );
    return BSON_OK;
}

int bson_append_bool( bson *b,  char *name,  bson_bool_t i ) {
    if ( bson_append_estart( b, bson_type.BSON_BOOL, name, 1 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append_byte( b , i != 0 );
    return BSON_OK;
}

int bson_append_null( bson *b,  char *name ) {
    if ( bson_append_estart( b , bson_type.BSON_NULL, name, 0 ) == BSON_ERROR )
        return BSON_ERROR;
    return BSON_OK;
}

int bson_append_undefined( bson *b,  char *name ) {
    if ( bson_append_estart( b, bson_type.BSON_UNDEFINED, name, 0 ) == BSON_ERROR )
        return BSON_ERROR;
    return BSON_OK;
}

int bson_append_string_base( bson *b,  char *name,
                              char *value, int len, bson_type type ) {

    int sl = len + 1;
    if ( bson_check_string( b, cast(  char * )value, sl - 1 ) == BSON_ERROR )
        return BSON_ERROR;
    if ( bson_append_estart( b, type, name, 4 + sl ) == BSON_ERROR ) {
        return BSON_ERROR;
    }
    bson_append32( b , &sl );
    bson_append( b , value , sl - 1 );
    bson_append( b , cast(char*)"\0" , 1 );
    return BSON_OK;
}

int bson_append_string( bson *b,  char *name,  char *value ) {
    return bson_append_string_base( b, name, value, strlen ( value ), bson_type.BSON_STRING );
}

int bson_append_symbol( bson *b,  char *name,  char *value ) {
    return bson_append_string_base( b, name, value, strlen ( value ), bson_type.BSON_SYMBOL );
}

int bson_append_code( bson *b,  char *name,  char *value ) {
    return bson_append_string_base( b, name, value, strlen ( value ), bson_type.BSON_CODE );
}

int bson_append_string_n( bson *b,  char *name,  char *value, int len ) {
    return bson_append_string_base( b, name, value, len, bson_type.BSON_STRING );
}

int bson_append_symbol_n( bson *b,  char *name,  char *value, int len ) {
    return bson_append_string_base( b, name, value, len, bson_type.BSON_SYMBOL );
}

int bson_append_code_n( bson *b,  char *name,  char *value, int len ) {
    return bson_append_string_base( b, name, value, len, bson_type.BSON_CODE );
}

int bson_append_code_w__scope_n( bson *b,  char *name,
                                 char *code, int len,  bson *_scope ) {

    int sl = len + 1;
    int size = 4 + 4 + sl + bson_size( _scope );
    if ( bson_append_estart( b, bson_type.BSON_CODEWSCOPE, name, size ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append32( b, &size );
    bson_append32( b, &sl );
    bson_append( b, code, sl );
    bson_append( b, _scope.data, bson_size( _scope ) );
    return BSON_OK;
}

int bson_append_code_w__scope( bson *b,  char *name,  char *code,  bson *_scope ) {
    return bson_append_code_w__scope_n( b, name, code, strlen ( code ), _scope );
}

int bson_append_binary( bson *b,  char *name, char type,  char *str, int len ) {
    if ( type == BSON_BIN_BINARY_OLD ) {
        int subtwolen = len + 4;
        if ( bson_append_estart( b, bson_type.BSON_BINDATA, name, 4+1+4+len ) == BSON_ERROR )
            return BSON_ERROR;
        bson_append32( b, &subtwolen );
        bson_append_byte( b, type );
        bson_append32( b, &len );
        bson_append( b, str, len );
    } else {
        if ( bson_append_estart( b, bson_type.BSON_BINDATA, name, 4+1+len ) == BSON_ERROR )
            return BSON_ERROR;
        bson_append32( b, &len );
        bson_append_byte( b, type );
        bson_append( b, str, len );
    }
    return BSON_OK;
}

int bson_append_oid( bson *b,  char *name,  bson_oid_t *oid ) {
    if ( bson_append_estart( b, bson_type.BSON_OID, name, 12 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append( b , oid , 12 );
    return BSON_OK;
}

int bson_append_new_oid( bson *b,  char *name ) {
    bson_oid_t oid;
    bson_oid_gen( &oid );
    return bson_append_oid( b, name, &oid );
}

int bson_append_regex( bson *b,  char *name,  char *pattern,  char *opts ) {
     int plen = strlen( pattern )+1;
     int olen = strlen( opts )+1;
    if ( bson_append_estart( b, bson_type.BSON_REGEX, name, plen + olen ) == BSON_ERROR )
        return BSON_ERROR;
    if ( bson_check_string( b, pattern, plen - 1 ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append( b , pattern , plen );
    bson_append( b , opts , olen );
    return BSON_OK;
}

int bson_append_bson( bson *b,  char *name,  bson *bson ) {
    if ( bson_append_estart( b, bson_type.BSON_OBJECT, name, bson_size( bson ) ) == BSON_ERROR )
        return BSON_ERROR;
    bson_append( b , bson.data , bson_size( bson ) );
    return BSON_OK;
}

int bson_append_element( bson *b,  char *name_or_null,  bson_iterator *elem ) {
    bson_iterator next = *elem;
    int size;

    bson_iterator_next( &next );
    size = next.cur - elem.cur;

    if ( name_or_null == null ) {
        if( bson_ensure_space( b, size ) == BSON_ERROR )
            return BSON_ERROR;
        bson_append( b, elem.cur, size );
    } else {
        int data_size = size - 2 - strlen( bson_iterator_key( elem ) );
        bson_append_estart( b, elem.cur[0], name_or_null, data_size );
        bson_append( b, bson_iterator_value( elem ), data_size );
    }

    return BSON_OK;
}

int bson_append_timestamp( bson *b,  char *name, bson_timestamp_t *ts ) {
    if ( bson_append_estart( b, bson_type.BSON_TIMESTAMP, name, 8 ) == BSON_ERROR ) return BSON_ERROR;

    bson_append32( b , &( ts.i ) );
    bson_append32( b , &( ts.t ) );

    return BSON_OK;
}

int bson_append_date( bson *b,  char *name, bson_date_t millis ) {
    if ( bson_append_estart( b, bson_type.BSON_DATE, name, 8 ) == BSON_ERROR ) return BSON_ERROR;
    bson_append64( b , &millis );
    return BSON_OK;
}

int bson_append_time_t( bson *b,  char *name, time_t secs ) {
    return bson_append_date( b, name, cast( bson_date_t )secs * 1000 );
}

int bson_append_start_object( bson *b,  char *name ) {
    if ( bson_append_estart( b, bson_type.BSON_OBJECT, name, 5 ) == BSON_ERROR ) return BSON_ERROR;
    b.stack[ b.stackPos++ ] = b.cur - b.data;
    bson_append32( b , &zero );
    return BSON_OK;
}

int bson_append_start_array( bson *b,  char *name ) {
    if ( bson_append_estart( b, bson_type.BSON_ARRAY, name, 5 ) == BSON_ERROR ) return BSON_ERROR;
    b.stack[ b.stackPos++ ] = b.cur - b.data;
    bson_append32( b , &zero );
    return BSON_OK;
}

int bson_append_finish_object( bson *b ) {
    char *start;
    int i;
    if ( bson_ensure_space( b, 1 ) == BSON_ERROR ) return BSON_ERROR;
    bson_append_byte( b , 0 );

    start = b.data + b.stack[ --b.stackPos ];
    i = b.cur - start;
    bson_little_endian32( start, &i );

    return BSON_OK;
}

int bson_append_finish_array( bson *b ) {
    return bson_append_finish_object( b );
}


/* Error handling and allocators. */

void function (  char *errmsg ) err_handler = null;

void function (  char *errmsg ) set_bson_err_handler( void function (  char *errmsg ) func ) {
    void function (  char *errmsg ) old = err_handler;
    err_handler = func;
    return old;
}

void *bson_malloc( int size ) {
    void *p;
    p = bson_malloc_func( size );
    bson_fatal_msg( !!p, cast(char*) "malloc() failed" );
    return p;
}

void *bson_realloc( void *ptr, int size ) {
    void *p;
    p = bson_realloc_func( ptr, size );
    bson_fatal_msg( !!p, cast(char*) "realloc() failed" );
    return p;
}

int _bson_errprintf(  char *format, ... ) {
    va_list ap;
    int ret;
    va_start( ap, format );
    ret = vfprintf( stderr, format, ap );
    va_end( ap );

    return ret;
}

/**
 * This method is invoked when a non-fatal bson error is encountered.
 * Calls the error handler if available.
 *
 *  @param
 */
void bson_builder_error( bson *b ) {
    if( err_handler )
        err_handler( cast(char*) "BSON error." );
}

void bson_fatal( int ok ) {
    bson_fatal_msg( ok, cast(char*) "" );
}

void bson_fatal_msg( int ok ,  char *msg ) {
    if ( ok )
        return;

    if ( err_handler ) {
        err_handler( msg );
    }

    bson_errprintf( cast(char*) "error: %s\n" , msg );
    exit( -5 );
}


/* Efficiently copy an integer to a string. */
//extern  char bson_numstrs[1000][4];

void bson_numstr( char *str, int i ) {
    if( i < 1000 )
        memcpy( str, bson_numstrs[i], 4 );
    else
        bson_sprintf( str,"%d", i );
}
/*
 * Copyright 2009-2011 10gen, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except _in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to _in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Portions Copyright 2001 Unicode, Inc.
 *
 * Disclaimer
 *
 * This source code is provided as is by Unicode, Inc. No claims are
 * made as to fitness for any particular purpose. No warranties of any
 * kind are expressed or implied. The recipient agrees to determine
 * applicability of information provided. If this file has been
 * purchased on magnetic or optical media from Unicode, Inc., the
 * sole remedy for any claim will be exchange of defective media
 * within 90 days of receipt.
 *
 * Limitations on Rights to Redistribute This Code
 *
 * Unicode, Inc. hereby grants the right to freely use the information
 * supplied _in this file _in the creation of products supporting the
 * Unicode Standard, and to make copies of this file _in any form
 * for internal or external distribution as long as this notice
 * remains attached.
 */


//#include "bson.h"
//#include "encoding.h"

/*
 * Index into the table below with the first byte of a UTF-8 sequence to
 * get the number of trailing bytes that are supposed to follow it.
 */
static char trailingBytesForUTF8[256] = [
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
];

/* --------------------------------------------------------------------- */

/*
 * Utility routine to tell whether a sequence of bytes is legal UTF-8.
 * This must be called with the length pre-determined by the first byte.
 * The length can be set by:
 *  length = trailingBytesForUTF8[*source]+1;
 * and the sequence is illegal right away if there aren't that many bytes
 * available.
 * If presented with a length > 4, this returns 0.  The Unicode
 * definition of UTF-8 goes up to 4-byte sequences.
 */
static int isLegalUTF8(  char *source, int length ) {
    char a;
     char *srcptr = source + length;
    switch ( length ) {
    default:
        return 0;
        /* Everything else falls through when "true"... */
    case 4:
        if ( ( a = ( *--srcptr ) ) < 0x80 || a > 0xBF ) return 0;
    case 3:
        if ( ( a = ( *--srcptr ) ) < 0x80 || a > 0xBF ) return 0;
    case 2:
        if ( ( a = ( *--srcptr ) ) > 0xBF ) return 0;
        switch ( *source ) {
            /* no fall-through _in this inner switch */
        case 0xE0:
            if ( a < 0xA0 ) return 0;
            break;
        case 0xF0:
            if ( a < 0x90 ) return 0;
            break;
        case 0xF4:
            if ( a > 0x8F ) return 0;
            break;
        default:
            if ( a < 0x80 ) return 0;
        }
    case 1:
        if ( *source >= 0x80 && *source < 0xC2 ) return 0;
        if ( *source > 0xF4 ) return 0;
    }
    return 1;
}

static int bson_validate_string( bson *b,  char *string,
                                  int length,  char check_utf8,  char check_dot,
                                  char check_dollar ) {

    int position = 0;
    int sequence_length = 1;

    if( check_dollar && string[0] == '$' ) {
        b.err |= BSON_FIELD_INIT_DOLLAR;
    }

    while ( position < length ) {
        if ( check_dot && *( string + position ) == '.' ) {
            b.err |= BSON_FIELD_HAS_DOT;
        }

        if ( check_utf8 ) {
            sequence_length = trailingBytesForUTF8[*( string + position )] + 1;
            if ( ( position + sequence_length ) > length ) {
                b.err |= BSON_NOT_UTF8;
                return BSON_ERROR;
            }
            if ( !isLegalUTF8( string + position, sequence_length ) ) {
                b.err |= BSON_NOT_UTF8;
                return BSON_ERROR;
            }
        }
        position += sequence_length;
    }

    return BSON_OK;
}


int bson_check_string( bson *b,  char *_string,
                        int length ) {

    return bson_validate_string( b, cast(  char * )_string, length, 1, 0, 0 );
}

int bson_check_field_name( bson *b,  char *_string,
                            int length ) {

    return bson_validate_string( b, cast(  char * )_string, length, 1, 1, 1 );
}
