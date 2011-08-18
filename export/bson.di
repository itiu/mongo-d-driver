// D import file generated from 'src/bson.d'
module bson;
private import std.c.stdlib;

private import std.c.string;

private import std.date;

private import std.c.stdio;

import std.stdarg;
private import bson_h;

private import numbers;

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

version (MONGO_BIG_ENDIAN)
{
}
else
{
    static void bson_little_endian64(void* outp, void* inp)
{
memcpy(outp,inp,8);
}

    static void bson_little_endian32(void* outp, void* inp)
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

int initialBufferSize = 128;
static int zero = 0;

alias malloc bson_malloc_func;
alias realloc bson_realloc_func;
alias free bson_free;
alias printf bson_printf;
alias fprintf bson_fprintf;
alias sprintf bson_sprintf;
alias _bson_errprintf bson_errprintf;
static int function() oid_fuzz_func = null;

static int function() oid_inc_func = null;

bson* bson_empty(bson* obj)
{
static char* data = cast(char*)"\x05\x00\x00\x00\x00";
bson_init_data(obj,data);
obj.finished = 1;
obj.err = 0;
obj.stackPos = 0;
return obj;
}
void bson_copy_basic(bson* _out, bson* _in);
void bson_copy(bson* _out, bson* _in);
int bson_init_data(bson* b, char* data)
{
b.data = data;
return BSON_OK;
}
static void _bson_reset(bson* b)
{
b.finished = 0;
b.stackPos = 0;
b.err = 0;
b.errstr = null;
}

int bson_size(bson* b);
char* bson_data(bson* b)
{
return cast(char*)b.data;
}
static char hexbyte(char hex);

void bson_oid_from_string(bson_oid_t* oid, char* str);
void bson_oid_to_string(bson_oid_t* oid, char* str);
void bson_set_oid_fuzz(int function() func)
{
oid_fuzz_func = func;
}
void bson_set_oid_inc(int function() func)
{
oid_inc_func = func;
}
void bson_oid_gen(bson_oid_t* oid);
time_t bson_oid_generated_time(bson_oid_t* oid)
{
time_t _out;
bson_big_endian32(&_out,&oid.ints[0]);
return _out;
}
void bson_print(bson* b)
{
bson_print_raw(b.data,0);
}
void bson_print_raw(char* data, int depth);
void bson_iterator_init(bson_iterator* i, bson* b)
{
i.cur = cast(char*)(b.data + 4);
i.first = 1;
}
void bson_iterator_from_buffer(bson_iterator* i, char* buffer)
{
i.cur = cast(char*)(buffer + 4);
i.first = 1;
}
bson_type bson_find(bson_iterator* it, bson* obj, char* name);
bson_bool_t bson_iterator_more(bson_iterator* i)
{
return *i.cur;
}
bson_type bson_iterator_next(bson_iterator* i);
bson_type bson_iterator_type(bson_iterator* i)
{
return cast(bson_type)i.cur[0];
}
char* bson_iterator_key(bson_iterator* i)
{
return cast(char*)(i.cur + 1);
}
char* bson_iterator_value(bson_iterator* i)
{
char* t = i.cur + 1;
t += strlen(t) + 1;
return t;
}
int bson_iterator_int_raw(bson_iterator* i)
{
int _out;
bson_little_endian32(&_out,bson_iterator_value(i));
return _out;
}
double bson_iterator_double_raw(bson_iterator* i)
{
double _out;
bson_little_endian64(&_out,bson_iterator_value(i));
return _out;
}
int64_t bson_iterator_long_raw(bson_iterator* i)
{
int64_t _out;
bson_little_endian64(&_out,bson_iterator_value(i));
return _out;
}
bson_bool_t bson_iterator_bool_raw(bson_iterator* i)
{
return bson_iterator_value(i)[0];
}
bson_oid_t* bson_iterator_oid(bson_iterator* i)
{
return cast(bson_oid_t*)bson_iterator_value(i);
}
int bson_iterator_int(bson_iterator* i);
double bson_iterator_double(bson_iterator* i);
int64_t bson_iterator_long(bson_iterator* i);
bson_timestamp_t bson_iterator_timestamp(bson_iterator* i)
{
bson_timestamp_t ts;
bson_little_endian32(&ts.i,bson_iterator_value(i));
bson_little_endian32(&ts.t,bson_iterator_value(i) + 4);
return ts;
}
bson_bool_t bson_iterator_bool(bson_iterator* i);
char* bson_iterator_string(bson_iterator* i)
{
return bson_iterator_value(i) + 4;
}
int bson_iterator_string_len(bson_iterator* i)
{
return bson_iterator_int_raw(i);
}
char* bson_iterator_code(bson_iterator* i);
void bson_iterator_code__scope(bson_iterator* i, bson* _scope);
bson_date_t bson_iterator_date(bson_iterator* i)
{
return bson_iterator_long_raw(i);
}
time_t bson_iterator_time_t(bson_iterator* i)
{
return cast(time_t)bson_iterator_date(i) / 1000;
}
int bson_iterator_bin_len(bson_iterator* i)
{
return bson_iterator_bin_type(i) == BSON_BIN_BINARY_OLD ? bson_iterator_int_raw(i) - 4 : bson_iterator_int_raw(i);
}
char bson_iterator_bin_type(bson_iterator* i)
{
return bson_iterator_value(i)[4];
}
char* bson_iterator_bin_data(bson_iterator* i)
{
return bson_iterator_bin_type(i) == BSON_BIN_BINARY_OLD ? bson_iterator_value(i) + 9 : bson_iterator_value(i) + 5;
}
char* bson_iterator_regex(bson_iterator* i)
{
return bson_iterator_value(i);
}
char* bson_iterator_regex_opts(bson_iterator* i)
{
char* p = bson_iterator_value(i);
return p + strlen(p) + 1;
}
void bson_iterator_subobject(bson_iterator* i, bson* sub)
{
bson_init_data(sub,cast(char*)bson_iterator_value(i));
_bson_reset(sub);
sub.finished = 1;
}
void bson_iterator_subiterator(bson_iterator* i, bson_iterator* sub)
{
bson_iterator_from_buffer(sub,bson_iterator_value(i));
}
static void _bson_init_size(bson* b, int size)
{
if (size == 0)
b.data = null;
else
b.data = cast(char*)bson_malloc(size);
b.dataSize = size;
b.cur = b.data + 4;
_bson_reset(b);
}

void bson_init(bson* b)
{
_bson_init_size(b,initialBufferSize);
}
void bson_init_size(bson* b, int size)
{
_bson_init_size(b,size);
}
void bson_append_byte(bson* b, char c)
{
b.cur[0] = c;
b.cur++;
}
void bson_append(bson* b, void* data, int len)
{
memcpy(b.cur,data,len);
b.cur += len;
}
void bson_append32(bson* b, void* data)
{
bson_little_endian32(b.cur,data);
b.cur += 4;
}
void bson_append64(bson* b, void* data)
{
bson_little_endian64(b.cur,data);
b.cur += 8;
}
int bson_ensure_space(bson* b, int bytesNeeded);
int bson_finish(bson* b);
void bson_destroy(bson* b)
{
bson_free(b.data);
b.err = 0;
b.data = null;
b.cur = null;
b.finished = 1;
}
static int bson_append_estart(bson* b, int type, char* name, int dataSize);

int bson_append_int(bson* b, char* name, int i);
int bson_append_long(bson* b, char* name, int64_t i);
int bson_append_double(bson* b, char* name, double d);
int bson_append_bool(bson* b, char* name, bson_bool_t i);
int bson_append_null(bson* b, char* name);
int bson_append_undefined(bson* b, char* name);
int bson_append_string_base(bson* b, char* name, char* value, int len, bson_type type);
int bson_append_string(bson* b, char* name, char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.BSON_STRING);
}
int bson_append_symbol(bson* b, char* name, char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.BSON_SYMBOL);
}
int bson_append_code(bson* b, char* name, char* value)
{
return bson_append_string_base(b,name,value,strlen(value),bson_type.BSON_CODE);
}
int bson_append_string_n(bson* b, char* name, char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.BSON_STRING);
}
int bson_append_symbol_n(bson* b, char* name, char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.BSON_SYMBOL);
}
int bson_append_code_n(bson* b, char* name, char* value, int len)
{
return bson_append_string_base(b,name,value,len,bson_type.BSON_CODE);
}
int bson_append_code_w__scope_n(bson* b, char* name, char* code, int len, bson* _scope);
int bson_append_code_w__scope(bson* b, char* name, char* code, bson* _scope)
{
return bson_append_code_w__scope_n(b,name,code,strlen(code),_scope);
}
int bson_append_binary(bson* b, char* name, char type, char* str, int len);
int bson_append_oid(bson* b, char* name, bson_oid_t* oid);
int bson_append_new_oid(bson* b, char* name)
{
bson_oid_t oid;
bson_oid_gen(&oid);
return bson_append_oid(b,name,&oid);
}
int bson_append_regex(bson* b, char* name, char* pattern, char* opts);
int bson_append_bson(bson* b, char* name, bson* bson);
int bson_append_element(bson* b, char* name_or_null, bson_iterator* elem);
int bson_append_timestamp(bson* b, char* name, bson_timestamp_t* ts);
int bson_append_date(bson* b, char* name, bson_date_t millis);
int bson_append_time_t(bson* b, char* name, time_t secs)
{
return bson_append_date(b,name,cast(bson_date_t)secs * 1000);
}
int bson_append_start_object(bson* b, char* name);
int bson_append_start_array(bson* b, char* name);
int bson_append_finish_object(bson* b);
int bson_append_finish_array(bson* b)
{
return bson_append_finish_object(b);
}
void function(char* errmsg) err_handler = null;
void function(char* errmsg) set_bson_err_handler(void function(char* errmsg) func)
{
void function(char* errmsg) old = err_handler;
err_handler = func;
return old;
}
void* bson_malloc(int size)
{
void* p;
p = bson_malloc_func(size);
bson_fatal_msg(!!p,cast(char*)"malloc() failed");
return p;
}
void* bson_realloc(void* ptr, int size)
{
void* p;
p = bson_realloc_func(ptr,size);
bson_fatal_msg(!!p,cast(char*)"realloc() failed");
return p;
}
int _bson_errprintf(char* format,...);
void bson_builder_error(bson* b)
{
if (err_handler)
err_handler(cast(char*)"BSON error.");
}
void bson_fatal(int ok)
{
bson_fatal_msg(ok,cast(char*)"");
}
void bson_fatal_msg(int ok, char* msg);
void bson_numstr(char* str, int i)
{
if (i < 1000)
memcpy(str,bson_numstrs[i],4);
else
bson_sprintf(str,"%d",i);
}
static char[256] trailingBytesForUTF8 = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5];

static int isLegalUTF8(char* source, int length);

static int bson_validate_string(bson* b, char* string, int length, char check_utf8, char check_dot, char check_dollar);

int bson_check_string(bson* b, char* _string, int length)
{
return bson_validate_string(b,cast(char*)_string,length,1,0,0);
}
int bson_check_field_name(bson* b, char* _string, int length)
{
return bson_validate_string(b,cast(char*)_string,length,1,1,1);
}
