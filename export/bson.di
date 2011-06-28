// D import file generated from 'src/bson.d'
module bson;
private import std.c.stdlib;

private import std.c.string;

private import std.date;

private import std.c.stdio;

version (D2)
{
    alias char _char;
}
version (D1)
{
    alias char _char;
}
public const static byte BSON_OK = 0;



public const static byte BSON_ERROR = -1;



public const static byte BSON_WARNING = -2;



public const static byte BSON_VALID = 0;



public const static byte BSON_NOT_UTF8 = 2;



public const static byte BSON_FIELD_HAS_DOT = 4;



public const static byte BSON_FIELD_INIT_DOLLAR = 8;



public const static byte BSON_OBJECT_FINISHED = 1;



alias long int64_t;
alias ulong uint64_t;
alias int time_t;
alias char* bson_err_handler;
enum bson_type 
{
bson_eoo = 0,
bson_double = 1,
bson_string = 2,
bson_object = 3,
bson_array = 4,
bson_bindata = 5,
bson_undefined = 6,
bson_oid = 7,
bson_bool = 8,
bson_date = 9,
bson_null = 10,
bson_regex = 11,
bson_dbref = 12,
bson_code = 13,
bson_symbol = 14,
bson_codewscope = 15,
bson_int = 16,
bson_timestamp = 17,
bson_long = 18,
}
alias int bson_bool_t;
struct bson
{
    char* data;
    bson_bool_t owned;
    int err;
    char* errstr;
}
struct bson_iterator
{
    char* cur = null;
    bson_bool_t first;
}
struct bson_buffer
{
    char* buf;
    char* cur;
    int bufSize;
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
static int initialBufferSize = 128;

static int zero = 0;

static bson* bson_empty(bson* obj)
{
static char* data = cast(char*)"\x05\x00\x00\x00\x00";
bson_init(obj,data,0);
return obj;
}

static void bson_copy(bson* _out, bson* _in);

static int bson_from_buffer(bson* b, bson_buffer* buf)
{
b.err = buf.err;
bson_buffer_finish(buf);
return bson_init(b,buf.buf,1);
}

static int bson_init(bson* b, char* data, bson_bool_t mine)
{
b.data = data;
b.owned = mine;
return BSON_OK;
}

static int bson_size(const bson* b);

static void bson_destroy(bson* b)
{
if (b.owned && b.data)
free(b.data);
b.data = null;
b.owned = 0;
}

static char hexbyte(char hex);

static void bson_oid_from_string(bson_oid_t* oid, char* str);

static void bson_oid_to_string(bson_oid_t* oid, char* str);

static void bson_oid_gen(bson_oid_t* oid);

static time_t bson_oid_generated_time(bson_oid_t* oid)
{
time_t _out;
bson_big_endian32(&_out,&oid.ints[0]);
return _out;
}

static void bson_print(bson* b)
{
bson_print_raw(b.data,0);
}

static void bson_print_raw(char* data, int depth);

static void bson_iterator_init(bson_iterator* i, char* bson)
{
i.cur = bson + 4;
i.first = 1;
}

static bson_type bson_find(bson_iterator* it, bson* obj, _char* name);

static bson_bool_t bson_iterator_more(bson_iterator* i)
{
return *i.cur;
}

static bson_type bson_iterator_next(bson_iterator* i);

static bson_type bson_iterator_type(bson_iterator* i)
{
return cast(bson_type)i.cur[0];
}

static char* bson_iterator_key(bson_iterator* i)
{
return i.cur + 1;
}

static char* bson_iterator_value(bson_iterator* i)
{
char* t = i.cur + 1;
t += strlen(t) + 1;
return t;
}

static int bson_iterator_int_raw(bson_iterator* i)
{
int _out;
bson_little_endian32(&_out,bson_iterator_value(i));
return _out;
}

static double bson_iterator_double_raw(bson_iterator* i)
{
double _out;
bson_little_endian64(&_out,bson_iterator_value(i));
return _out;
}

static int64_t bson_iterator_long_raw(bson_iterator* i)
{
int64_t _out;
bson_little_endian64(&_out,bson_iterator_value(i));
return _out;
}

static bson_bool_t bson_iterator_bool_raw(bson_iterator* i)
{
return bson_iterator_value(i)[0];
}

static bson_oid_t* bson_iterator_oid(bson_iterator* i)
{
return cast(bson_oid_t*)bson_iterator_value(i);
}

static int bson_iterator_int(bson_iterator* i);

static double bson_iterator_double(bson_iterator* i);

static int64_t bson_iterator_long(bson_iterator* i);

static bson_timestamp_t bson_iterator_timestamp(bson_iterator* i)
{
bson_timestamp_t ts;
bson_little_endian32(&ts.i,bson_iterator_value(i));
bson_little_endian32(&ts.t,bson_iterator_value(i) + 4);
return ts;
}

static bson_bool_t bson_iterator_bool(bson_iterator* i);

static char* bson_iterator_string(bson_iterator* i)
{
return bson_iterator_value(i) + 4;
}

int bson_iterator_string_len(bson_iterator* i)
{
return bson_iterator_int_raw(i);
}
static char* bson_iterator_code(bson_iterator* i);

static void bson_iterator_code_scope(bson_iterator* i, bson* _scope);

static bson_date_t bson_iterator_date(bson_iterator* i)
{
return bson_iterator_long_raw(i);
}

static time_t bson_iterator_time_t(bson_iterator* i)
{
return cast(int)bson_iterator_date(i) / 1000;
}

static int bson_iterator_bin_len(bson_iterator* i)
{
return bson_iterator_bin_type(i) == 2 ? bson_iterator_int_raw(i) - 4 : bson_iterator_int_raw(i);
}

static char bson_iterator_bin_type(bson_iterator* i)
{
return bson_iterator_value(i)[4];
}

static char* bson_iterator_bin_data(bson_iterator* i)
{
return bson_iterator_bin_type(i) == 2 ? bson_iterator_value(i) + 9 : bson_iterator_value(i) + 5;
}

static char* bson_iterator_regex(bson_iterator* i)
{
return bson_iterator_value(i);
}

static char* bson_iterator_regex_opts(bson_iterator* i)
{
char* p = bson_iterator_value(i);
return p + strlen(p) + 1;
}

static void bson_iterator_subobject(bson_iterator* i, bson* sub)
{
bson_init(sub,cast(char*)bson_iterator_value(i),0);
}

static void bson_iterator_subiterator(bson_iterator* i, bson_iterator* sub)
{
bson_iterator_init(sub,bson_iterator_value(i));
}

static int bson_buffer_init(bson_buffer* b)
{
b.buf = cast(char*)bson_malloc(initialBufferSize);
b.bufSize = initialBufferSize;
b.cur = b.buf + 4;
b.finished = 0;
b.stackPos = 0;
b.err = 0;
b.errstr = null;
return 0;
}

static void bson_append_byte(bson_buffer* b, char c)
{
b.cur[0] = c;
b.cur++;
}

static void bson_append(bson_buffer* b, const void* data, int len)
{
memcpy(b.cur,data,len);
b.cur += len;
}

static void bson_append32(bson_buffer* b, const void* data)
{
bson_little_endian32(b.cur,data);
b.cur += 4;
}

static void bson_append64(bson_buffer* b, const void* data)
{
bson_little_endian64(b.cur,data);
b.cur += 8;
}

static int bson_ensure_space(bson_buffer* b, int bytesNeeded);

static int bson_buffer_finish(bson_buffer* b);

static void bson_buffer_destroy(bson_buffer* b)
{
free(b.buf);
b.err = 0;
b.buf = null;
b.cur = null;
b.finished = 1;
}

static int bson_append_estart(bson_buffer* b, int type, const char* name, int dataSize);

static int bson_append_estartA(bson_buffer* b, int type, string name, int dataSize);

int bson_append_int(bson_buffer* b, const char* name, int i);
static int bson_append_long(bson_buffer* b, const char* name, int64_t i);

static int bson_append_double(bson_buffer* b, const char* name, double d);

static int bson_append_bool(bson_buffer* b, const char* name, bson_bool_t i);

static int bson_append_null(bson_buffer* b, const char* name);

static int bson_append_undefined(bson_buffer* b, const char* name);

static int bson_append_string_base(bson_buffer* b, const char* name, const char* value, int len, bson_type type);

static int bson_append_stringA_base(bson_buffer* b, string name, string value, bson_type type);

static int bson_append_string(bson_buffer* b, const char* name, const char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.bson_string);
}

static int bson_append_symbol(bson_buffer* b, const char* name, const char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.bson_symbol);
}

static int bson_append_code(bson_buffer* b, const char* name, const char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.bson_code);
}

static int bson_append_string_n(bson_buffer* b, const char* name, const char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.bson_string);
}

static int bson_append_symbol_n(bson_buffer* b, const char* name, const char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.bson_symbol);
}

static int bson_append_code_n(bson_buffer* b, const char* name, const char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.bson_code);
}

static int bson_append_code_w_scope_n(bson_buffer* b, const char* name, const char* code, int len, bson* _scope);

static int bson_append_code_w_scope(bson_buffer* b, const char* name, char* code, bson* _scope)
{
return bson_append_code_w_scope_n(b,name,code,strlen(code),_scope);
}

static int bson_append_binary(bson_buffer* b, const char* name, char type, char* str, int len);

static int bson_append_oid(bson_buffer* b, const char* name, bson_oid_t* oid);

static int bson_append_new_oid(bson_buffer* b, const char* name)
{
bson_oid_t oid;
bson_oid_gen(&oid);
return bson_append_oid(b,name,&oid);
}

static int bson_append_regex(bson_buffer* b, const char* name, char* pattern, char* opts);

static int bson_append_bson(bson_buffer* b, const char* name, bson* bson);

static int bson_append_element(bson_buffer* b, const char* name_or_null, bson_iterator* elem);

static int bson_append_timestamp(bson_buffer* b, const char* name, bson_timestamp_t* ts);

static int bson_append_date(bson_buffer* b, const char* name, bson_date_t millis);

static int bson_append_time_t(bson_buffer* b, const char* name, time_t secs)
{
return bson_append_date(b,name,cast(bson_date_t)secs * 1000);
}

static int bson_append_start_object(bson_buffer* b, const char* name);

static int bson_append_start_array(bson_buffer* b, const char* name);

static int bson_append_finish_object(bson_buffer* b);

static void* bson_malloc(int size)
{
void* p = malloc(size);
bson_fatal_msg(!!p,cast(char*)"malloc() failed");
return p;
}

static void* bson_realloc(void* ptr, int size)
{
void* p = realloc(ptr,size);
bson_fatal_msg(!!p,cast(char*)"realloc() failed");
return p;
}

static bson_err_handler err_handler = null;

static bson_err_handler set_bson_err_handler(bson_err_handler func)
{
bson_err_handler old = err_handler;
err_handler = func;
return old;
}

static void bson_builder_error(bson_buffer* b)
{
}

static void bson_fatal(int ok)
{
bson_fatal_msg(ok,cast(char*)"");
}

static void bson_fatal_msg(int ok, char* msg);

const char[4][1000] bson_numstrs;

static void bson_numstr(char* str, int i)
{
if (i < 1000)
memcpy(str,cast(char*)bson_numstrs[i],4);
else
sprintf(str,cast(char*)"%d",i);
}

const char[256] trailingBytesForUTF8 = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5];

static int isLegalUTF8(const char* source, int length);

static int bson_validate_string(bson_buffer* b, const char* string, const int length, const char check_utf8, const char check_dot, const char check_dollar);

static int bson_check_string(bson_buffer* b, const char* string, const int length)
{
return bson_validate_string(b,string,length,1,0,0);
}

static int bson_check_field_name(bson_buffer* b, const char* string, const int length)
{
return bson_validate_string(b,string,length,1,1,1);
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

version (MONGO_BIG_ENDIAN)
{
}
else
{
    static void bson_little_endian64(void* outp, const void* inp)
{
memcpy(outp,inp,8);
}

    static void bson_little_endian32(void* outp, const void* inp)
{
memcpy(outp,inp,4);
}

    static void bson_big_endian32(void* outp, void* inp)
{
bson_swap_endian32(cast(char*)outp,cast(char*)inp);
}

    static void bson_big_endian64(void* outp, void* inp)
{
bson_swap_endian64(cast(char*)outp,cast(char*)inp);
}

}
static int bson_append_stringA(bson_buffer* b, string name, string value)
{
return bson_append_stringA_base(b,name,value,bson_type.bson_string);
}

static int bson_append_regexA(bson_buffer* b, string name, string pattern, string opts);

