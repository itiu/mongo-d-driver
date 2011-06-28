module bson;

private import std.c.stdlib;
private import std.c.string;
private import std.date;
private import std.c.stdio;

version(D2)
{
	alias char _char;
}

version(D1)
{
	alias char _char;
}

/* bson.c */

/*    Copyright 2009, 2010 10gen Inc.
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

/* Generic error and warning flags. */
public const static byte BSON_OK = 0;
public const static byte BSON_ERROR = -1;
public const static byte BSON_WARNING = -2;

/* BSON validity flags. */
public const static byte BSON_VALID = 0x0;
public const static byte BSON_NOT_UTF8 = 0x2; /**< Either a key or a string is not valid UTF-8. */
public const static byte BSON_FIELD_HAS_DOT = 0x4; /**< Warning: key contains '.' character. */
public const static byte BSON_FIELD_INIT_DOLLAR = 0x8; /**< Warning: key starts with '$' character. */

/* BSON error codes. */
public const static byte BSON_OBJECT_FINISHED = 1; /**< Trying to modify a finished BSON object. */

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
	bson_dbref = 12, /* deprecated */
	bson_code = 13,
	bson_symbol = 14,
	bson_codewscope = 15,
	bson_int = 16,
	bson_timestamp = 17,
	bson_long = 18
};

alias int bson_bool_t;

struct bson
{
	char* data;
	bson_bool_t owned;
	int err; /**< Bitfield representing errors or warnings on this bson object. */
	char* errstr; /**< A string representation of the most recent error or warning. */
};

struct bson_iterator
{
	char* cur = null;
	bson_bool_t first;
};

struct bson_buffer
{
	char* buf;
	char* cur;
	int bufSize;
	bson_bool_t finished;
	int stack[32];
	int stackPos;
	int err; /**< Bitfield representing errors or warnings on this buffer */
	char* errstr; /**< A string representation of the most recent error or warning. */
};

union bson_oid_t
{
	char bytes[12];
	int ints[3];
};

alias int64_t bson_date_t;

struct bson_timestamp_t
{
	int i; /* increment */
	int t; /* time in seconds */
};

///////////////////////////////////////////////////////////////////////////////

static int initialBufferSize = 128;

/* only need one of these */
static int zero = 0;

/* ----------------------------
 READING
 ------------------------------ */

static bson* bson_empty(bson* obj)
{
	static char* data = cast(char*) "\005\0\0\0\0";
	bson_init(obj, data, 0);
	return obj;
}

static void bson_copy(bson* _out, bson* _in)
{
	if(!_out)
		return;
	_out.data = cast(char*) bson_malloc(bson_size(_in));
	_out.owned = 1;
	memcpy(_out.data, _in.data, bson_size(_in));
}

static int bson_from_buffer(bson* b, bson_buffer* buf)
{
	b.err = buf.err;
	bson_buffer_finish(buf);
	return bson_init(b, buf.buf, 1);
}

static int bson_init(bson* b, char* data, bson_bool_t mine)
{
	b.data = data;
	b.owned = mine;
	return BSON_OK;
}

static int bson_size(const bson* b)
{
	int i;
	if(!b || !b.data)
		return 0;
	bson_little_endian32(cast(void*) &i, cast(void*) b.data);
	return i;
}

static void bson_destroy(bson* b)
{
	if(b.owned && b.data)
		free(b.data);
	b.data = null;
	b.owned = 0;
}

static char hexbyte(char hex)
{
	switch(hex)
	{
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

static void bson_oid_from_string(bson_oid_t* oid, char* str)
{
	int i;
	for(i = 0; i < 12; i++)
	{
		oid.bytes[i] = cast(char) (hexbyte(str[2 * i]) << 4) | hexbyte(str[2 * i + 1]);
	}
}

static void bson_oid_to_string(bson_oid_t* oid, char* str)
{
	static char hex[16] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
	int i;
	for(i = 0; i < 12; i++)
	{
		str[2 * i] = hex[(oid.bytes[i] & 0xf0) >> 4];
		str[2 * i + 1] = hex[oid.bytes[i] & 0x0f];
	}
	str[24] = '\0';
}

static void bson_oid_gen(bson_oid_t* oid)
{
	static int incr = 0;
	static int fuzz = 0;
	int i = incr++; /*TODO make atomic*/
	int t = cast(int) toInteger(getLocalTZA());

	/* TODO rand sucks. find something better */
	if(!fuzz)
	{
		srand(t);
		fuzz = rand();
	}

	bson_big_endian32(&oid.ints[0], &t);
	oid.ints[1] = fuzz;
	bson_big_endian32(&oid.ints[2], &i);
}

static time_t bson_oid_generated_time(bson_oid_t* oid)
{
	time_t _out;
	bson_big_endian32(&_out, &oid.ints[0]);
	return _out;
}

static void bson_print(bson* b)
{
	bson_print_raw(b.data, 0);
}

static void bson_print_raw(char* data, int depth)
{
	bson_iterator i;
	char* key;
	int temp;
	char oidhex[25];
	bson_iterator_init(&i, data);
	bson_timestamp_t ts;

	while(bson_iterator_next(&i))
	{
		bson_type t = bson_iterator_type(&i);
		if(t == 0)
			break;
		key = bson_iterator_key(&i);

		for(temp = 0; temp <= depth; temp++)
			printf("\t");
		printf("%s : %d \t ", key, t);
		switch(t)
		{
			case bson_type.bson_int:
				printf("%d", bson_iterator_int(&i));
			break;
			case bson_type.bson_double:
				printf("%f", bson_iterator_double(&i));
			break;
			case bson_type.bson_bool:
				printf("%s", bson_iterator_bool(&i) ? "true" : "false");
			break;
			case bson_type.bson_string:
				printf("%s", bson_iterator_string(&i));
			break;
			case bson_type.bson_null:
				printf("null");
			break;
			case bson_type.bson_oid:
				bson_oid_to_string(bson_iterator_oid(&i), cast(char*) &oidhex);
				printf("%s", oidhex);
			break;
			case bson_type.bson_timestamp:
				ts = bson_iterator_timestamp(&i);
				printf("i: %d, t: %d", ts.i, ts.t);
			break;

			case bson_type.bson_object:
			case bson_type.bson_array:
				printf("\n");
				bson_print_raw(bson_iterator_value(&i), depth + 1);
			break;
			default:
				fprintf(stderr, "can't print type : %d\n", t);
		}
		printf("\n");
	}
}

/* ----------------------------
 ITERATOR
 ------------------------------ */

static void bson_iterator_init(bson_iterator* i, char* bson)
{
	i.cur = bson + 4;
	i.first = 1;
}

static bson_type bson_find(bson_iterator* it, bson* obj, _char* name)
{
	bson_iterator_init(it, obj.data);
	while(bson_iterator_next(it))
	{
		if(strcmp(cast(char*) name, bson_iterator_key(it)) == 0)
			break;
	}
	return bson_iterator_type(it);
}

static bson_bool_t bson_iterator_more(bson_iterator* i)
{
	return *(i.cur);
}

static bson_type bson_iterator_next(bson_iterator* i)
{
	int ds;

	if(i.first)
	{
		i.first = 0;
		return cast(bson_type) *(i.cur);
	}

	switch(bson_iterator_type(i))
	{
		case bson_type.bson_eoo:
			return bson_type.bson_eoo; /* don't advance */
		case bson_type.bson_undefined:
		case bson_type.bson_null:
			ds = 0;
		break;
		case bson_type.bson_bool:
			ds = 1;
		break;
		case bson_type.bson_int:
			ds = 4;
		break;
		case bson_type.bson_long:
		case bson_type.bson_double:
		case bson_type.bson_timestamp:
		case bson_type.bson_date:
			ds = 8;
		break;
		case bson_type.bson_oid:
			ds = 12;
		break;
		case bson_type.bson_string:
		case bson_type.bson_symbol:
		case bson_type.bson_code:
			ds = 4 + bson_iterator_int_raw(i);
		break;
		case bson_type.bson_bindata:
			ds = 5 + bson_iterator_int_raw(i);
		break;
		case bson_type.bson_object:
		case bson_type.bson_array:
		case bson_type.bson_codewscope:
			ds = bson_iterator_int_raw(i);
		break;
		case bson_type.bson_dbref:
			ds = 4 + 12 + bson_iterator_int_raw(i);
		break;
		case bson_type.bson_regex:
		{
			char* s = bson_iterator_value(i);
			char* p = s;
			p += strlen(p) + 1;
			p += strlen(p) + 1;
			ds = p - s;
			break;
		}

		default:
		{
			char msg[] = cast(char[]) "unknown type: 000000000000";
			bson_numstr(cast(char*) (&msg + 14), cast(int) (i.cur[0]));
			bson_fatal_msg(0, cast(char*) &msg);
			return cast(bson_type) 0;
		}
	}

	i.cur += 1 + strlen(i.cur + 1) + 1 + ds;

	return cast(bson_type) *(i.cur);
}

static bson_type bson_iterator_type(bson_iterator* i)
{
	return cast(bson_type) i.cur[0];
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

/* types */

static int bson_iterator_int_raw(bson_iterator* i)
{
	int _out;
	bson_little_endian32(&_out, bson_iterator_value(i));
	return _out;
}

static double bson_iterator_double_raw(bson_iterator* i)
{
	double _out;
	bson_little_endian64(&_out, bson_iterator_value(i));
	return _out;
}

static int64_t bson_iterator_long_raw(bson_iterator* i)
{
	int64_t _out;
	bson_little_endian64(&_out, bson_iterator_value(i));
	return _out;
}

static bson_bool_t bson_iterator_bool_raw(bson_iterator* i)
{
	return bson_iterator_value(i)[0];
}

static bson_oid_t* bson_iterator_oid(bson_iterator* i)
{
	return cast(bson_oid_t*) bson_iterator_value(i);
}

static int bson_iterator_int(bson_iterator* i)
{
	switch(bson_iterator_type(i))
	{
		case bson_type.bson_int:
			return bson_iterator_int_raw(i);
		case bson_type.bson_long:
			return cast(int) bson_iterator_long_raw(i);
		case bson_type.bson_double:
			return cast(int) bson_iterator_double_raw(i);
		default:
			return 0;
	}
}

static double bson_iterator_double(bson_iterator* i)
{
	switch(bson_iterator_type(i))
	{
		case bson_type.bson_int:
			return bson_iterator_int_raw(i);
		case bson_type.bson_long:
			return bson_iterator_long_raw(i);
		case bson_type.bson_double:
			return bson_iterator_double_raw(i);
		default:
			return 0;
	}
}

static int64_t bson_iterator_long(bson_iterator* i)
{
	switch(bson_iterator_type(i))
	{
		case bson_type.bson_int:
			return bson_iterator_int_raw(i);
		case bson_type.bson_long:
			return bson_iterator_long_raw(i);
		case bson_type.bson_double:
			return cast(int64_t) bson_iterator_double_raw(i);
		default:
			return 0;
	}
}

static bson_timestamp_t bson_iterator_timestamp(bson_iterator* i)
{
	bson_timestamp_t ts;
	bson_little_endian32(&(ts.i), bson_iterator_value(i));
	bson_little_endian32(&(ts.t), bson_iterator_value(i) + 4);
	return ts;
}

static bson_bool_t bson_iterator_bool(bson_iterator* i)
{
	switch(bson_iterator_type(i))
	{
		case bson_type.bson_bool:
			return bson_iterator_bool_raw(i);
		case bson_type.bson_int:
			return bson_iterator_int_raw(i) != 0;
		case bson_type.bson_long:
			return bson_iterator_long_raw(i) != 0;
		case bson_type.bson_double:
			return bson_iterator_double_raw(i) != 0;
		case bson_type.bson_eoo:
		case bson_type.bson_null:
			return 0;
		default:
			return 1;
	}
}

static char* bson_iterator_string(bson_iterator* i)
{
	return bson_iterator_value(i) + 4;
}

int bson_iterator_string_len(bson_iterator* i)
{
	return bson_iterator_int_raw(i);
}

static char* bson_iterator_code(bson_iterator* i)
{
	switch(bson_iterator_type(i))
	{
		case bson_type.bson_string:
		case bson_type.bson_code:
			return bson_iterator_value(i) + 4;
		case bson_type.bson_codewscope:
			return bson_iterator_value(i) + 8;
		default:
			return null;
	}
}

static void bson_iterator_code_scope(bson_iterator* i, bson* _scope)
{
	if(bson_iterator_type(i) == bson_type.bson_codewscope)
	{
		int code_len;
		bson_little_endian32(&code_len, bson_iterator_value(i) + 4);
		bson_init(_scope, cast(char*) (bson_iterator_value(i) + 8 + code_len), 0);
	} else
	{
		bson_empty(_scope);
	}
}

static bson_date_t bson_iterator_date(bson_iterator* i)
{
	return bson_iterator_long_raw(i);
}

static time_t bson_iterator_time_t(bson_iterator* i)
{
	return cast(int) bson_iterator_date(i) / 1000;
}

static int bson_iterator_bin_len(bson_iterator* i)
{
	return (bson_iterator_bin_type(i) == 2) ? bson_iterator_int_raw(i) - 4 : bson_iterator_int_raw(i);
}

static char bson_iterator_bin_type(bson_iterator* i)
{
	return bson_iterator_value(i)[4];
}

static char* bson_iterator_bin_data(bson_iterator* i)
{
	return (bson_iterator_bin_type(i) == 2) ? bson_iterator_value(i) + 9 : bson_iterator_value(i) + 5;
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
	bson_init(sub, cast(char*) bson_iterator_value(i), 0);
}

static void bson_iterator_subiterator(bson_iterator* i, bson_iterator* sub)
{
	bson_iterator_init(sub, bson_iterator_value(i));
}

/* ----------------------------
 BUILDING
 ------------------------------ */

static int bson_buffer_init(bson_buffer* b)
{
	b.buf = cast(char*) bson_malloc(initialBufferSize);
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
	memcpy(b.cur, data, len);
	b.cur += len;
}

static void bson_append32(bson_buffer* b, const void* data)
{
	bson_little_endian32(b.cur, data);
	b.cur += 4;
}

static void bson_append64(bson_buffer* b, const void* data)
{
	bson_little_endian64(b.cur, data);
	b.cur += 8;
}

static int bson_ensure_space(bson_buffer* b, int bytesNeeded)
{
	int pos = b.cur - b.buf;
	char* orig = b.buf;
	int new_size;

	if(b.finished)
	{
		b.err = BSON_OBJECT_FINISHED;
		return BSON_ERROR;
	}

	if(pos + bytesNeeded <= b.bufSize)
		return BSON_OK;

	new_size = cast(int) (1.5 * (b.bufSize + bytesNeeded));
	b.buf = cast(char*) realloc(b.buf, new_size);
	if(!b.buf)
		bson_fatal_msg(!!b.buf, cast(char*) "realloc() failed");

	b.bufSize = new_size;
	b.cur += b.buf - orig;

	return BSON_OK;
}

/**
 * Add null byte, mark as finished, and return buffer.
 * Note that the buffer will now be owned by the bson
 * object created from a call to bson_from_buffer.
 * This buffer is then deallocated by calling
 * bson_destroy().
 */
static int bson_buffer_finish(bson_buffer* b)
{
	int i;
	if(!b.finished)
	{
		if(bson_ensure_space(b, 1) == BSON_ERROR)
			return BSON_ERROR;
		bson_append_byte(b, 0);
		i = b.cur - b.buf;
		bson_little_endian32(b.buf, &i);
		b.finished = 1;
	}

	return BSON_OK;
}

static void bson_buffer_destroy(bson_buffer* b)
{
	free(b.buf);
	b.err = 0;
	b.buf = null;
	b.cur = null;
	b.finished = 1;
}

static int bson_append_estart(bson_buffer* b, int type, const char* name, int dataSize)
{
	int len = strlen(name) + 1;
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
	bson_append(b, name, len);
	return BSON_OK;
}

// ++
static int bson_append_estartA(bson_buffer* b, int type, string name, int dataSize)
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

/* ----------------------------
 BUILDING TYPES
 ------------------------------ */

int bson_append_int(bson_buffer* b, const char* name, int i)
{
	if(bson_append_estart(b, bson_type.bson_int, name, 4) == BSON_ERROR)
		return BSON_ERROR;
	bson_append32(b, &i);
	return BSON_OK;
}

static int bson_append_long(bson_buffer* b, const char* name, int64_t i)
{
	if(bson_append_estart(b, bson_type.bson_long, name, 8) == BSON_ERROR)
		return BSON_ERROR;
	bson_append64(b, &i);
	return BSON_OK;
}

static int bson_append_double(bson_buffer* b, const char* name, double d)
{
	if(bson_append_estart(b, bson_type.bson_double, name, 8) == BSON_ERROR)
		return BSON_ERROR;
	bson_append64(b, &d);
	return BSON_OK;
}

static int bson_append_bool(bson_buffer* b, const char* name, bson_bool_t i)
{
	if(bson_append_estart(b, bson_type.bson_bool, name, 1) == BSON_ERROR)
		return BSON_ERROR;
	bson_append_byte(b, i != 0);
	return BSON_OK;
}

static int bson_append_null(bson_buffer* b, const char* name)
{
	if(bson_append_estart(b, bson_type.bson_null, name, 0) == BSON_ERROR)
		return BSON_ERROR;
	return BSON_OK;
}

static int bson_append_undefined(bson_buffer* b, const char* name)
{
	if(bson_append_estart(b, bson_type.bson_undefined, name, 0) == BSON_ERROR)
		return BSON_ERROR;
	return BSON_OK;
}

static int bson_append_string_base(bson_buffer* b, const char* name, const char* value, int len, bson_type type)
{
	int sl = len + 1;
	if(bson_check_string(b, value, sl - 1) == BSON_ERROR)
		return BSON_ERROR;
	if(bson_append_estart(b, type, name, 4 + sl) == BSON_ERROR)
	{
		return BSON_ERROR;
	}
	bson_append32(b, &sl);
	bson_append(b, value, sl - 1);
	bson_append_byte(b, cast(char) 0);
//	bson_append(b, cast(char*) "\0", 1);
	return BSON_OK;
}
//++
static int bson_append_stringA_base(bson_buffer* b, string name, string value, bson_type type)
{
	int sl = value.length + 1;
	if(bson_check_string(b, cast(char*) value, sl - 1) == BSON_ERROR)
		return BSON_ERROR;
	if(bson_append_estartA(b, type, name, 4 + sl) == BSON_ERROR)
	{
		return BSON_ERROR;
	}
	bson_append32(b, &sl);
	bson_append(b, cast(char*) value, sl - 1);
	//	bson_append(b, cast (char*)"\0", 1);
	bson_append_byte(b, cast(char) 0);
	return BSON_OK;
}


static int bson_append_string(bson_buffer* b, const char* name, const char* value)
{
	return bson_append_string_base(b, name, value, strlen(value), bson_type.bson_string);
}

static int bson_append_symbol(bson_buffer* b, const char* name, const char* value)
{
	return bson_append_string_base(b, name, value, strlen(value), bson_type.bson_symbol);
}

static int bson_append_code(bson_buffer* b, const char* name, const char* value)
{
	return bson_append_string_base(b, name, value, strlen(value), bson_type.bson_code);
}

static int bson_append_string_n(bson_buffer* b, const char* name, const char* value, int len)
{
	return bson_append_string_base(b, name, value, len, bson_type.bson_string);
}

static int bson_append_symbol_n(bson_buffer* b, const char* name, const char* value, int len)
{
	return bson_append_string_base(b, name, value, len, bson_type.bson_symbol);
}

static int bson_append_code_n(bson_buffer* b, const char* name, const char* value, int len)
{
	return bson_append_string_base(b, name, value, len, bson_type.bson_code);
}

static int bson_append_code_w_scope_n(bson_buffer* b, const char* name, const char* code, int len, bson* _scope)
{

	int sl = len + 1;
	int size = 4 + 4 + sl + bson_size(_scope);
	if(bson_append_estart(b, bson_type.bson_codewscope, name, size) == BSON_ERROR)
		return BSON_ERROR;
	bson_append32(b, &size);
	bson_append32(b, &sl);
	bson_append(b, code, sl);
	bson_append(b, _scope.data, bson_size(_scope));
	return BSON_OK;
}

static int bson_append_code_w_scope(bson_buffer* b, const char* name, char* code, bson* _scope)
{
	return bson_append_code_w_scope_n(b, name, code, strlen(code), _scope);
}

static int bson_append_binary(bson_buffer* b, const char* name, char type, char* str, int len)
{
	if(type == 2)
	{
		int subtwolen = len + 4;
		if(bson_append_estart(b, bson_type.bson_bindata, name, 4 + 1 + 4 + len) == BSON_ERROR)
			return BSON_ERROR;
		bson_append32(b, &subtwolen);
		bson_append_byte(b, type);
		bson_append32(b, &len);
		bson_append(b, str, len);
	} else
	{
		if(bson_append_estart(b, bson_type.bson_bindata, name, 4 + 1 + len) == BSON_ERROR)
			return BSON_ERROR;
		bson_append32(b, &len);
		bson_append_byte(b, type);
		bson_append(b, str, len);
	}
	return BSON_OK;
}

static int bson_append_oid(bson_buffer* b, const char* name, bson_oid_t* oid)
{
	if(bson_append_estart(b, bson_type.bson_oid, name, 12) == BSON_ERROR)
		return BSON_ERROR;
	bson_append(b, oid, 12);
	return BSON_OK;
}

static int bson_append_new_oid(bson_buffer* b, const char* name)
{
	bson_oid_t oid;
	bson_oid_gen(&oid);
	return bson_append_oid(b, name, &oid);
}

static int bson_append_regex(bson_buffer* b, const char* name, char* pattern, char* opts)
{
	int plen = strlen(pattern) + 1;
	int olen = strlen(opts) + 1;
	if(bson_append_estart(b, bson_type.bson_regex, name, plen + olen) == BSON_ERROR)
		return BSON_ERROR;
	if(bson_check_string(b, pattern, plen - 1) == BSON_ERROR)
		return BSON_ERROR;
	bson_append(b, pattern, plen);
	bson_append(b, opts, olen);
	return BSON_OK;
}

static int bson_append_bson(bson_buffer* b, const char* name, bson* bson)
{
	if(bson_append_estart(b, bson_type.bson_object, name, bson_size(bson)) == BSON_ERROR)
		return BSON_ERROR;
	bson_append(b, bson.data, bson_size(bson));
	return BSON_OK;
}

static int bson_append_element(bson_buffer* b, const char* name_or_null, bson_iterator* elem)
{
	bson_iterator next = *elem;
	int size;

	bson_iterator_next(&next);
	size = next.cur - elem.cur;

	if(name_or_null == null)
	{
		if(bson_ensure_space(b, size) == BSON_ERROR)
			return BSON_ERROR;
		bson_append(b, elem.cur, size);
	} else
	{
		int data_size = size - 2 - strlen(bson_iterator_key(elem));
		bson_append_estart(b, elem.cur[0], name_or_null, data_size);
		bson_append(b, bson_iterator_value(elem), data_size);
	}

	return BSON_OK;
}

static int bson_append_timestamp(bson_buffer* b, const char* name, bson_timestamp_t* ts)
{
	if(bson_append_estart(b, bson_type.bson_timestamp, name, 8) == BSON_ERROR)
		return BSON_ERROR;

	bson_append32(b, &(ts.i));
	bson_append32(b, &(ts.t));

	return BSON_OK;
}

static int bson_append_date(bson_buffer* b, const char* name, bson_date_t millis)
{
	if(bson_append_estart(b, bson_type.bson_date, name, 8) == BSON_ERROR)
		return BSON_ERROR;
	bson_append64(b, &millis);
	return BSON_OK;
}

static int bson_append_time_t(bson_buffer* b, const char* name, time_t secs)
{
	return bson_append_date(b, name, cast(bson_date_t) secs * 1000);
}

static int bson_append_start_object(bson_buffer* b, const char* name)
{
	if(bson_append_estart(b, bson_type.bson_object, name, 5) == BSON_ERROR)
		return BSON_ERROR;
	b.stack[b.stackPos++] = b.cur - b.buf;
	bson_append32(b, &zero);
	return BSON_OK;
}

static int bson_append_start_array(bson_buffer* b, const char* name)
{
	if(bson_append_estart(b, bson_type.bson_array, name, 5) == BSON_ERROR)
		return BSON_ERROR;
	b.stack[b.stackPos++] = b.cur - b.buf;
	bson_append32(b, &zero);
	return BSON_OK;
}

static int bson_append_finish_object(bson_buffer* b)
{
	char* start;
	int i;
	if(bson_ensure_space(b, 1) == BSON_ERROR)
		return BSON_ERROR;
	bson_append_byte(b, 0);

	start = b.buf + b.stack[--b.stackPos];
	i = b.cur - start;
	bson_little_endian32(start, &i);

	return BSON_OK;
}

static void* bson_malloc(int size)
{
	void* p = malloc(size);
	bson_fatal_msg(!!p, cast(char*) "malloc() failed");
	return p;
}

static void* bson_realloc(void* ptr, int size)
{
	void* p = realloc(ptr, size);
	bson_fatal_msg(!!p, cast(char*) "realloc() failed");
	return p;
}

static bson_err_handler err_handler = null;

static bson_err_handler set_bson_err_handler(bson_err_handler func)
{
	bson_err_handler old = err_handler;
	err_handler = func;
	return old;
}

/**
 * This method is invoked when a non-fatal bson error is encountered.
 * Calls the error handler if available.
 *
 *  @param
 */
static void bson_builder_error(bson_buffer* b)
{
	//??	if(err_handler)
	//??		err_handler(cast (char*)"BSON error.");
}

static void bson_fatal(int ok)
{
	bson_fatal_msg(ok, cast(char*) "");
}

static void bson_fatal_msg(int ok, char* msg)
{
	if(ok)
		return;

	//??	if(err_handler)
	//??	{
	//??		err_handler(msg);
	//??	}

	fprintf(stderr, cast(char*) "error: %s\n", msg);
	exit(-5);
}

const char bson_numstrs[1000][4];

static void bson_numstr(char* str, int i)
{
	if(i < 1000)
		memcpy(str, cast(char*) bson_numstrs[i], 4);
	else
		sprintf(str, cast(char*) "%d", i);
}

//////////////////////////////////////////////////////////////////////////////////////////////

const char trailingBytesForUTF8[256] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3,
		4, 4, 4, 4, 5, 5, 5, 5];

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

static int isLegalUTF8(const char* source, int length)
{
	char a;
	char* srcptr = cast(char*) (source + length);
	switch(length)
	{
		default:
			return 0;
			/* Everything else falls through when "true"... */
		case 4:
			if((a = (*--srcptr)) < 0x80 || a > 0xBF)
				return 0;
		case 3:
			if((a = (*--srcptr)) < 0x80 || a > 0xBF)
				return 0;
		case 2:
			if((a = (*--srcptr)) > 0xBF)
				return 0;
			switch(*source)
			{
				/* no fall-through in this inner switch */
				case 0xE0:
					if(a < 0xA0)
						return 0;
				break;
				case 0xF0:
					if(a < 0x90)
						return 0;
				break;
				case 0xF4:
					if(a > 0x8F)
						return 0;
				break;
				default:
					if(a < 0x80)
						return 0;
			}
		case 1:
			if(*source >= 0x80 && *source < 0xC2)
				return 0;
			if(*source > 0xF4)
				return 0;
	}
	return 1;
}

static int bson_validate_string(bson_buffer* b, const char* string, const int length, const char check_utf8,
		const char check_dot, const char check_dollar)
{
	if(string is null)
		return BSON_ERROR;

	int position = 0;
	int sequence_length = 1;

	if(check_dollar && string[0] == '$')
	{
		b.err |= BSON_FIELD_INIT_DOLLAR;
	}

	while(position < length)
	{
		if(check_dot && *(string + position) == '.')
		{
			b.err |= BSON_FIELD_HAS_DOT;
		}

		if(check_utf8)
		{
			sequence_length = trailingBytesForUTF8[*(string + position)] + 1;
			if((position + sequence_length) > length)
			{
				b.err |= BSON_NOT_UTF8;
				return BSON_ERROR;
			}
			if(!isLegalUTF8(string + position, sequence_length))
			{
				b.err |= BSON_NOT_UTF8;
				return BSON_ERROR;
			}
		}
		position += sequence_length;
	}

	return BSON_OK;
}

static int bson_check_string(bson_buffer* b, const char* string, const int length)
{
	return bson_validate_string(b, string, length, 1, 0, 0);
}

static int bson_check_field_name(bson_buffer* b, const char* string, const int length)
{
	return bson_validate_string(b, string, length, 1, 1, 1);
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

version(MONGO_BIG_ENDIAN)
{
//	#define bson_little_endian64(out, in) ( bson_swap_endian64(out, in) )
//	#define bson_little_endian32(out, in) ( bson_swap_endian32(out, in) )

//	#define bson_big_endian32(out, in) ( memcpy(out, in, 4) )
} else
{
	//#else

	//#define bson_little_endian64(out, in) ( memcpy(out, in, 8) )
	static void bson_little_endian64(void* outp, const void* inp)
	{
		memcpy(outp, inp, 8);
	}

	//#define bson_little_endian32(out, in) ( memcpy(out, in, 4) )
	static void bson_little_endian32(void* outp, const void* inp)
	{
		memcpy(outp, inp, 4);
	}

	//#define bson_big_endian32(out, in) ( bson_swap_endian32(out, in) )
	static void bson_big_endian32(void* outp, void* inp)
	{
		bson_swap_endian32(cast(char*) outp, cast(char*) inp);
	}

	//#define bson_big_endian64(out, in) ( bson_swap_endian64(out, in) )
	static void bson_big_endian64(void* outp, void* inp)
	{
		bson_swap_endian64(cast(char*) outp, cast(char*) inp);
	}
//	#endif
}

///

static int bson_append_stringA(bson_buffer* b, string name, string value)
{
	return bson_append_stringA_base(b, name, value, bson_type.bson_string);
}

static int bson_append_regexA(bson_buffer* b, string name, string pattern, string opts)
{
	int plen = 1;
	if(pattern !is null)
		plen = pattern.length + 1;

	int olen = 1;
	if(opts !is null)
		olen = opts.length + 1;

	if(bson_append_estartA(b, bson_type.bson_regex, name, plen + olen) == BSON_ERROR)
		return BSON_ERROR;

	if(bson_check_string(b, cast(char*) pattern, plen - 1) == BSON_ERROR)
			return BSON_ERROR;

	bson_append(b, cast(char*) pattern, plen - 1);
	bson_append_byte(b, cast(char) 0);
	bson_append(b, cast(char*) opts, olen - 1);
	bson_append_byte(b, cast(char) 0);

	return BSON_OK;
}
