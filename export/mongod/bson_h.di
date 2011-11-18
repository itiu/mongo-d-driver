// D import file generated from 'src/mongod/bson_h.d'
module mongod.bson_h;
alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;
alias int time_t;
int INT_MIN = -32767;
int INT_MAX = 32767;
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
    int[32] stack;
    int stackPos;
    int err;
    char* errstr;
}
union bson_oid_t
{
    char[12] bytes;
    int[3] ints;
}
alias int64_t bson_date_t;
struct bson_timestamp_t
{
    int i;
    int t;
}
