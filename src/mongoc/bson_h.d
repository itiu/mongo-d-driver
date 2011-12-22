module mongoc.bson_h;

private import std.string;

public static byte BSON_OK = 0;
public static byte BSON_ERROR= -1;

enum  {
    BSON_SIZE_OVERFLOW = 1 /**< Trying to create a BSON object larger than INT_MAX. */
};

enum  {
    BSON_VALID = 0,                 /**< BSON is valid and UTF-8 compliant. */
    BSON_NOT_UTF8 = ( 1<<1 ),       /**< A key or a string is not valid UTF-8. */
    BSON_FIELD_HAS_DOT = ( 1<<2 ),  /**< Warning: key contains '.' character. */
    BSON_FIELD_INIT_DOLLAR = ( 1<<3 ), /**< Warning: key starts with '$' character. */
    BSON_ALREADY_FINISHED = ( 1<<4 )  /**< Trying to modify a finished BSON object. */
};

enum {
    BSON_BIN_BINARY = 0,
    BSON_BIN_FUNC = 1,
    BSON_BIN_BINARY_OLD = 2,
    BSON_BIN_UUID = 3,
    BSON_BIN_MD5 = 5,
    BSON_BIN_USER = 128
};

enum bson_type{
    BSON_EOO = 0,
    BSON_DOUBLE = 1,
    BSON_STRING = 2,
    BSON_OBJECT = 3,
    BSON_ARRAY = 4,
    BSON_BINDATA = 5,
    BSON_UNDEFINED = 6,
    BSON_OID = 7,
    BSON_BOOL = 8,
    BSON_DATE = 9,
    BSON_NULL = 10,
    BSON_REGEX = 11,
    BSON_DBREF = 12, /**< Deprecated. */
    BSON_CODE = 13,
    BSON_SYMBOL = 14,
    BSON_CODEWSCOPE = 15,
    BSON_INT = 16,
    BSON_TIMESTAMP = 17,
    BSON_LONG = 18
};

alias int bson_bool_t;

struct bson_iterator{
    char *cur;
    bson_bool_t first;
} ;

struct bson{
    char *data;
    char *cur;
    int dataSize;
    bson_bool_t finished;
    int stack[32];
    int stackPos;
    int err; /**< Bitfield representing errors or warnings on this buffer */
    char *errstr; /**< A string representation of the most recent error or warning. */
} ;

static int zero = 0;

extern (C) void bson_iterator_init( bson_iterator *i,  bson *b );
extern (C) char *bson_iterator_key( bson_iterator *i );
extern (C) char *bson_iterator_value( bson_iterator *i );
extern (C) char *bson_iterator_string( bson_iterator *i );
extern (C) int bson_iterator_int( bson_iterator *i );
extern (C) double bson_iterator_double( bson_iterator *i );
extern (C) bson_bool_t bson_iterator_bool( bson_iterator *i );
extern (C) void bson_iterator_subiterator( bson_iterator *i, bson_iterator *sub );
extern (C) char *bson_iterator_regex( bson_iterator *i );

extern (C) void bson_init( bson *b );
extern (C) int bson_finish( bson *b );
extern (C) void bson_destroy( bson *b );
extern (C) int bson_check_string( bson *b,  char *_string, int length );
extern (C) void bson_append_byte( bson *b, char c );
extern (C) void bson_append( bson *b,  void *data, int len );
extern (C) void bson_append32( bson *b,  void *data );
extern (C) void bson_append64( bson *b,  void *data );
extern (C) int bson_ensure_space( bson *b,  int bytesNeeded );
extern (C) int bson_check_field_name( bson *b,  char *_string, int length );
extern (C) void bson_builder_error( bson *b );
extern (C) int bson_append_start_object(bson* b, char* name);
extern (C) int bson_append_finish_object( bson *b );
extern (C) static int bson_append_estart(bson* b, int type, char* name, int dataSize);
                                                        

// ++ stringz . string

static int _bson_append_string(bson* b, string name, string value)
{
	return _bson_append_string_base(b, name, value, bson_type.BSON_STRING);
}

static int _bson_append_string_base(bson* b, string name, string value, bson_type type)
{
	int sl = (cast (uint)value.length) + 1;
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

	int len = (cast (uint)name.length) + 1;
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
	bson_append(b, cast(char*) name, len-1);
	bson_append_byte(b, 0);
	return BSON_OK;
}

static int _bson_append_start_array(bson* b, string name)
{
	if(_bson_append_estart(b, bson_type.BSON_ARRAY, name, 5) == BSON_ERROR)
		return BSON_ERROR;
	b.stack[b.stackPos++] = cast(int)(b.cur - b.data);
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
	b.stack[b.stackPos++] = cast(int)(b.cur - b.data);
	bson_append32(b, &zero);
	return BSON_OK;
}

static int _bson_append_regex(bson* b, string name, string pattern, string opts)
{
	int plen = 1;
	if(pattern !is null)
		plen = (cast(uint)pattern.length) + 1;

	int olen = 1;
	if(opts !is null)
		olen = (cast(uint)opts.length) + 1;

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

