// D import file generated from 'src/mongoc/bson_h.d'
module mongoc.bson_h;
public static byte BSON_OK = 0;


public static byte BSON_ERROR = -1;


enum 
{
BSON_SIZE_OVERFLOW = 1,
}
enum 
{
BSON_VALID = 0,
BSON_NOT_UTF8 = 1 << 1,
BSON_FIELD_HAS_DOT = 1 << 2,
BSON_FIELD_INIT_DOLLAR = 1 << 3,
BSON_ALREADY_FINISHED = 1 << 4,
}
enum 
{
BSON_BIN_BINARY = 0,
BSON_BIN_FUNC = 1,
BSON_BIN_BINARY_OLD = 2,
BSON_BIN_UUID = 3,
BSON_BIN_MD5 = 5,
BSON_BIN_USER = 128,
}
enum bson_type 
{
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
BSON_DBREF = 12,
BSON_CODE = 13,
BSON_SYMBOL = 14,
BSON_CODEWSCOPE = 15,
BSON_INT = 16,
BSON_TIMESTAMP = 17,
BSON_LONG = 18,
}
alias int bson_bool_t;
struct bson_iterator
{
    char* cur;
    bson_bool_t first;
}
struct bson
{
    char* data;
    char* cur;
    int dataSize;
    bson_bool_t finished;
    long[32] stack;
    int stackPos;
    int err;
    char* errstr;
}
static int zero = 0;

extern (C) void bson_iterator_init(bson_iterator* i, bson* b);

extern (C) char* bson_iterator_key(bson_iterator* i);

extern (C) char* bson_iterator_value(bson_iterator* i);

extern (C) char* bson_iterator_string(bson_iterator* i);

extern (C) int bson_iterator_int(bson_iterator* i);

extern (C) double bson_iterator_double(bson_iterator* i);

extern (C) bson_bool_t bson_iterator_bool(bson_iterator* i);

extern (C) void bson_iterator_subiterator(bson_iterator* i, bson_iterator* sub);

extern (C) char* bson_iterator_regex(bson_iterator* i);

extern (C) void bson_init(bson* b);

extern (C) int bson_finish(bson* b);

extern (C) void bson_destroy(bson* b);

extern (C) int bson_check_string(bson* b, char* _string, int length);

extern (C) void bson_append_byte(bson* b, char c);

extern (C) void bson_append(bson* b, void* data, int len);

extern (C) void bson_append32(bson* b, void* data);

extern (C) void bson_append64(bson* b, void* data);

extern (C) int bson_ensure_space(bson* b, int bytesNeeded);

extern (C) int bson_check_field_name(bson* b, char* _string, int length);

extern (C) void bson_builder_error(bson* b);

extern (C) int bson_append_finish_object(bson* b);

static int _bson_append_string(bson* b, string name, string value)
{
return _bson_append_string_base(b,name,value,bson_type.BSON_STRING);
}

static int _bson_append_string_base(bson* b, string name, string value, bson_type type);

static int _bson_append_estart(bson* b, int type, string name, int dataSize);

static int _bson_append_start_array(bson* b, string name);

static int _bson_append_int(bson* b, string name, int i);

static int _bson_append_start_object(bson* b, string name);

static int _bson_append_regex(bson* b, string name, string pattern, string opts);

