module bson;

private import std.c.stdlib;
private import std.c.string;
private import std.date;
private import std.c.stdio;

version (D2)
{
    alias const char const_char;
}
version (D1)
{
    alias char const_char;
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

//#include "bson.h"
alias int bson_bool_t;

struct bson
{
	char* data;
	bson_bool_t owned;
};

struct bson_buffer
{
	char* buf;
	char* cur;
	int bufSize;
	bson_bool_t finished;
	int stack[32];
	int stackPos;
};

union bson_oid_t
{
	char bytes[12];
	int ints[3];
};

struct bson_iterator
{
	char* cur;
	bson_bool_t first;
};

alias int time_t;

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

alias long int64_t;

alias int64_t bson_date_t;

alias char* bson_err_handler;

void bson_swap_endian64(char* outp, char* inp)
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

void bson_swap_endian32(char* outp, char* inp)
{
	outp[0] = inp[3];
	outp[1] = inp[2];
	outp[2] = inp[1];
	outp[3] = inp[0];
}

version(MONGO_BIG_ENDIAN)
{
//#define bson_little_endian64(out, in) ( bson_swap_endian64(out, in) )
//#define bson_little_endian32(out, in) ( bson_swap_endian32(out, in) )

//#define bson_big_endian32(out, in) ( memcpy(out, in, 4) )
} else
{
	//#else

	//#define bson_little_endian64(out, in) ( memcpy(out, in, 8) )
	void bson_little_endian64(void* outp, void* inp)
	{
		memcpy(outp, inp, 8);
	}

	//#define bson_little_endian32(out, in) ( memcpy(out, in, 4) )
	void bson_little_endian32(void* outp, void* inp)
	{
		memcpy(outp, inp, 4);
	}

	//#define bson_big_endian32(out, in) ( bson_swap_endian32(out, in) )
	void bson_big_endian32(void* outp, void* inp)
	{
		bson_swap_endian32(cast(char*) outp, cast(char*) inp);
	}

	//#define bson_big_endian64(out, in) ( bson_swap_endian64(out, in) )
	void bson_big_endian64(void* outp, void* inp)
	{
		bson_swap_endian64(cast(char*) outp, cast(char*) inp);
	}
//#endif
}

//#include <stdlib.h>
//#include <string.h>
//#include <stdio.h>
//#include <time.h>

const int initialBufferSize = 128;

/* only need one of these */
static int zero = 0;

/* ----------------------------
 READING
 ------------------------------ */

bson* bson_empty(bson* obj)
{
	static char* data = cast(char*)"\005\0\0\0\0";
	return bson_init(obj, data, 0);
}

void bson_copy(bson* _out, bson* _in)
{
	if(!_out)
		return;
	_out.data = cast(char*) bson_malloc(bson_size(_in));
	_out.owned = 1;
	memcpy(_out.data, _in.data, bson_size(_in));
}

bson* bson_from_buffer(bson* b, bson_buffer* buf)
{
	return bson_init(b, bson_buffer_finish(buf), 1);
}

bson* bson_init(bson* b, char* data, bson_bool_t mine)
{
	b.data = data;
	b.owned = mine;
	return b;
}

int bson_size(bson* b)
{
	int i;
	if(!b || !b.data)
		return 0;
	bson_little_endian32(cast(void*) &i, cast(void*) b.data);
	return i;
}

void bson_destroy(bson* b)
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

void bson_oid_from_string(bson_oid_t* oid, char* str)
{
	int i;
	for(i = 0; i < 12; i++)
	{
		oid.bytes[i] = cast(char)(hexbyte(str[2 * i]) << 4) | hexbyte(str[2 * i + 1]);
	}
}

void bson_oid_to_string(bson_oid_t* oid, char* str)
{
	static const char hex[16] = ['0', '1', '2', '3', '4', '5', '6', '7', '8',
			'9', 'a', 'b', 'c', 'd', 'e', 'f'];
	int i;
	for(i = 0; i < 12; i++)
	{
		str[2 * i] = hex[(oid.bytes[i] & 0xf0) >> 4];
		str[2 * i + 1] = hex[oid.bytes[i] & 0x0f];
	}
	str[24] = '\0';
}

void bson_oid_gen(bson_oid_t* oid)
{
	static int incr = 0;
	static int fuzz = 0;
	int i = incr++; /*TODO make atomic*/
	int t = cast(int)toInteger (getLocalTZA());

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

time_t bson_oid_generated_time(bson_oid_t* oid)
{
	time_t _out;
	bson_big_endian32(&_out, &oid.ints[0]);
	return _out;
}

void bson_print(bson* b)
{
	bson_print_raw(b.data, 0);
}

void bson_print_raw(char* data, int depth)
{
	bson_iterator i;
	char* key;
	int temp;
	char oidhex[25];
	bson_iterator_init(&i, data);

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
			break; //@@@ cast (char*)&oidhex)
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

void bson_iterator_init(bson_iterator* i, char* bson)
{
	i.cur = bson + 4;
	i.first = 1;
}

bson_type bson_find(bson_iterator* it, bson* obj, const_char* name)
{
	bson_iterator_init(it, obj.data);
	while(bson_iterator_next(it))
	{
		if(strcmp(cast(char*)name, bson_iterator_key(it)) == 0)
			break;
	}
	return bson_iterator_type(it);
}

bson_bool_t bson_iterator_more(bson_iterator* i)
{
	return *(i.cur);
}

bson_type bson_iterator_next(bson_iterator* i)
{
	int ds;

	if(i.first)
	{
		i.first = 0;
		return cast(bson_type) (i.cur);
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
			char msg[] = cast(char[])"unknown type: 000000000000";
			bson_numstr(cast(char*) (&msg + 14), cast(int) (i.cur[0]));
			bson_fatal_msg(0, cast(char*) &msg);
			return cast(bson_type) 0;
		}
	}

	i.cur += 1 + strlen(i.cur + 1) + 1 + ds;

	return cast(bson_type) (i.cur);
}

bson_type bson_iterator_type(bson_iterator* i)
{
	return cast(bson_type) i.cur[0];
}

char* bson_iterator_key(bson_iterator* i)
{
	return i.cur + 1;
}

char* bson_iterator_value(bson_iterator* i)
{
	char* t = i.cur + 1;
	t += strlen(t) + 1;
	return t;
}

/* types */

int bson_iterator_int_raw(bson_iterator* i)
{
	int _out;
	bson_little_endian32(&_out, bson_iterator_value(i));
	return _out;
}

double bson_iterator_double_raw(bson_iterator* i)
{
	double _out;
	bson_little_endian64(&_out, bson_iterator_value(i));
	return _out;
}

int64_t bson_iterator_long_raw(bson_iterator* i)
{
	int64_t _out;
	bson_little_endian64(&_out, bson_iterator_value(i));
	return _out;
}

bson_bool_t bson_iterator_bool_raw(bson_iterator* i)
{
	return bson_iterator_value(i)[0];
}

bson_oid_t* bson_iterator_oid(bson_iterator* i)
{
	return cast(bson_oid_t*) bson_iterator_value(i);
}

int bson_iterator_int(bson_iterator* i)
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

double bson_iterator_double(bson_iterator* i)
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

int64_t bson_iterator_long(bson_iterator* i)
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

bson_bool_t bson_iterator_bool(bson_iterator* i)
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

char* bson_iterator_string(bson_iterator* i)
{
	return bson_iterator_value(i) + 4;
}

int bson_iterator_string_len(bson_iterator* i)
{
	return bson_iterator_int_raw(i);
}

char* bson_iterator_code(bson_iterator* i)
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

void bson_iterator_code_scope(bson_iterator* i, bson* _scope)
{
	if(bson_iterator_type(i) == bson_type.bson_codewscope)
	{
		int code_len;
		bson_little_endian32(&code_len, bson_iterator_value(i) + 4);
		bson_init(_scope, cast(char*) (bson_iterator_value(i) + 8 + code_len),
				0);
	} else
	{
		bson_empty(_scope);
	}
}

bson_date_t bson_iterator_date(bson_iterator* i)
{
	return bson_iterator_long_raw(i);
}

time_t bson_iterator_time_t(bson_iterator* i)
{
	return cast (int) bson_iterator_date(i) / 1000;
}

int bson_iterator_bin_len(bson_iterator* i)
{
	return bson_iterator_int_raw(i);
}

char bson_iterator_bin_type(bson_iterator* i)
{
	return bson_iterator_value(i)[4];
}

char* bson_iterator_bin_data(bson_iterator* i)
{
	return bson_iterator_value(i) + 5;
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
	bson_init(sub, cast(char*) bson_iterator_value(i), 0);
}

void bson_iterator_subiterator(bson_iterator* i, bson_iterator* sub)
{
	bson_iterator_init(sub, bson_iterator_value(i));
}

/* ----------------------------
 BUILDING
 ------------------------------ */

bson_buffer* bson_buffer_init(bson_buffer* b)
{
	b.buf = cast(char*) bson_malloc(initialBufferSize);
	b.bufSize = initialBufferSize;
	b.cur = b.buf + 4;
	b.finished = 0;
	b.stackPos = 0;
	return b;
}

void bson_append_byte(bson_buffer* b, char c)
{
	b.cur[0] = c;
	b.cur++;
}

void bson_append(bson_buffer* b, void* data, int len)
{
	memcpy(b.cur, data, len);
	b.cur += len;
}

void bson_append32(bson_buffer* b, void* data)
{
	bson_little_endian32(b.cur, data);
	b.cur += 4;
}

void bson_append64(bson_buffer* b, void* data)
{
	bson_little_endian64(b.cur, data);
	b.cur += 8;
}

bson_buffer* bson_ensure_space(bson_buffer* b, int bytesNeeded)
{
	int pos = b.cur - b.buf;
	char* orig = b.buf;
	int new_size;

	if(b.finished)
		bson_fatal_msg(!!b.buf, cast (char*) "trying to append to finished buffer");

	if(pos + bytesNeeded <= b.bufSize)
		return b;

	new_size = cast(int) (1.5 * (b.bufSize + bytesNeeded));
	b.buf = cast(char*) realloc(cast(void*) b.buf, new_size);
	if(!b.buf)
		bson_fatal_msg(!!b.buf, cast (char*) "realloc() failed");

	b.bufSize = new_size;
	b.cur += b.buf - orig;

	return b;
}

char* bson_buffer_finish(bson_buffer* b)
{
	int i;
	if(!b.finished)
	{
		if(!bson_ensure_space(b, 1))
			return null;
		bson_append_byte(b, 0);
		i = b.cur - b.buf;
		bson_little_endian32(b.buf, &i);
		b.finished = 1;
	}
	return b.buf;
}

void bson_buffer_destroy(bson_buffer* b)
{
	free(b.buf);
	b.buf = null;
	b.cur = null;
	b.finished = 1;
}

static bson_buffer* bson_append_estart(bson_buffer* b, int type, const_char* name, int dataSize)
{
	int sl = strlen(cast(char*)name) + 1;
	if(!bson_ensure_space(b, 1 + sl + dataSize))
		return null;
	bson_append_byte(b, cast(char) type);
	bson_append(b, cast(char*)name, sl);
	return b;
}


/* ----------------------------
 BUILDING TYPES
 ------------------------------ */

bson_buffer* bson_append_int(bson_buffer* b, const_char* name, int i)
{
	if(!bson_append_estart(b, bson_type.bson_int, name, 4))
		return null;
	bson_append32(b, &i);
	return b;
}

bson_buffer* bson_append_long(bson_buffer* b, const_char* name, int64_t i)
{
	if(!bson_append_estart(b, bson_type.bson_long, name, 8))
		return null;
	bson_append64(b, &i);
	return b;
}

bson_buffer* bson_append_double(bson_buffer* b, const_char* name, double d)
{
	if(!bson_append_estart(b, bson_type.bson_double, name, 8))
		return null;
	bson_append64(b, &d);
	return b;
}

bson_buffer* bson_append_bool(bson_buffer* b, const_char* name, bson_bool_t i)
{
	if(!bson_append_estart(b, bson_type.bson_bool, name, 1))
		return null;
	bson_append_byte(b, i != 0);
	return b;
}

bson_buffer* bson_append_null(bson_buffer* b, const_char* name)
{
	if(!bson_append_estart(b, bson_type.bson_null, name, 0))
		return null;
	return b;
}

bson_buffer* bson_append_undefined(bson_buffer* b, const_char* name)
{
	if(!bson_append_estart(b, bson_type.bson_undefined, name, 0))
		return null;
	return b;
}

bson_buffer* bson_append_string_base(bson_buffer* b, const_char* name, char* value,
		bson_type type)
{
	int sl = strlen(value) + 1;
	if(!bson_append_estart(b, type, name, 4 + sl))
		return null;
	bson_append32(b, &sl);
	bson_append(b, value, sl);
	return b;
}

bson_buffer* bson_append_string(bson_buffer* b, const_char* name, char* value)
{
	return bson_append_string_base(b, name, value, bson_type.bson_string);
}

bson_buffer* bson_append_symbol(bson_buffer* b, const_char* name, char* value)
{
	return bson_append_string_base(b, name, value, bson_type.bson_symbol);
}

bson_buffer* bson_append_code(bson_buffer* b, const_char* name, char* value)
{
	return bson_append_string_base(b, name, value, bson_type.bson_code);
}

bson_buffer* bson_append_code_w_scope(bson_buffer* b, const_char* name, char* code,
		bson* _scope)
{
	int sl = strlen(code) + 1;
	int size = 4 + 4 + sl + bson_size(_scope);
	if(!bson_append_estart(b, bson_type.bson_codewscope, name, size))
		return null;
	bson_append32(b, &size);
	bson_append32(b, &sl);
	bson_append(b, code, sl);
	bson_append(b, _scope.data, bson_size(_scope));
	return b;
}

bson_buffer* bson_append_binary(bson_buffer* b, const_char* name, char type,
		char* str, int len)
{
	if(!bson_append_estart(b, bson_type.bson_bindata, name, 4 + 1 + len))
		return null;
	bson_append32(b, &len);
	bson_append_byte(b, type);
	bson_append(b, str, len);
	return b;
}

bson_buffer* bson_append_oid(bson_buffer* b, const_char* name, bson_oid_t* oid)
{
	if(!bson_append_estart(b, bson_type.bson_oid, name, 12))
		return null;
	bson_append(b, oid, 12);
	return b;
}

bson_buffer* bson_append_new_oid(bson_buffer* b, const_char* name)
{
	bson_oid_t oid;
	bson_oid_gen(&oid);
	return bson_append_oid(b, name, &oid);
}

bson_buffer* bson_append_regex(bson_buffer* b, const_char* name, char* pattern,
		char* opts)
{
	int plen = strlen(pattern) + 1;
	int olen = strlen(opts) + 1;
	if(!bson_append_estart(b, bson_type.bson_regex, name, plen + olen))
		return null;
	bson_append(b, pattern, plen);
	bson_append(b, opts, olen);
	return b;
}

bson_buffer* bson_append_bson(bson_buffer* b, const_char* name, bson* bson)
{
	if(!bson_append_estart(b, bson_type.bson_object, name, bson_size(bson)))
		return null;
	bson_append(b, bson.data, bson_size(bson));
	return b;
}

bson_buffer* bson_append_element(bson_buffer* b, const_char* name_or_null,
		bson_iterator* elem)
{
	bson_iterator next = *elem;
	int size;

	bson_iterator_next(&next);
	size = next.cur - elem.cur;

	if(name_or_null is null)
	{
		bson_ensure_space(b, size);
		bson_append(b, elem.cur, size);
	} else
	{
		int data_size = size - 1 - strlen(bson_iterator_key(elem));
		bson_append_estart(b, elem.cur[0], name_or_null, data_size);
		bson_append(b, cast(void*)name_or_null, strlen(cast(char*)name_or_null));
		bson_append(b, bson_iterator_value(elem), data_size);
	}

	return b;
}

bson_buffer* bson_append_date(bson_buffer* b, const_char* name, bson_date_t millis)
{
	if(!bson_append_estart(b, bson_type.bson_date, name, 8))
		return null;
	bson_append64(b, &millis);
	return b;
}

bson_buffer* bson_append_time_t(bson_buffer* b, const_char* name, time_t secs)
{
	return bson_append_date(b, name, cast(bson_date_t) secs * 1000);
}

bson_buffer* bson_append_start_object(bson_buffer* b, const_char* name)
{
	if(!bson_append_estart(b, bson_type.bson_object, name, 5))
		return null;
	b.stack[b.stackPos++] = b.cur - b.buf;
	bson_append32(b, &zero);
	return b;
}

bson_buffer* bson_append_start_array(bson_buffer* b, const_char* name)
{
	if(!bson_append_estart(b, bson_type.bson_array, name, 5))
		return null;
	b.stack[b.stackPos++] = b.cur - b.buf;
	bson_append32(b, &zero);
	return b;
}

bson_buffer* bson_append_finish_object(bson_buffer* b)
{
	char* start;
	int i;
	if(!bson_ensure_space(b, 1))
		return null;
	bson_append_byte(b, 0);

	start = b.buf + b.stack[--b.stackPos];
	i = b.cur - start;
	bson_little_endian32(start, &i);

	return b;
}

void* bson_malloc(int size)
{
	void* p = malloc(size);
	bson_fatal_msg(!!p, cast(char*)"malloc() failed");
	return p;
}

static bson_err_handler err_handler = null;

bson_err_handler set_bson_err_handler(bson_err_handler func)
{
	bson_err_handler old = err_handler;
	err_handler = func;
	return old;
}

void bson_fatal(int ok)
{
	bson_fatal_msg(ok, cast(char*)"");
}

void bson_fatal_msg(int ok, char* msg)
{
	if(ok)
		return;

	if(err_handler)
	{
		//        err_handler(msg); @@@???
	}

	fprintf(stderr, "error: %s\n", msg);
	exit(-5);
}

const char bson_numstrs[1000][4];

void bson_numstr(char* str, int i)
{
	if(i < 1000)
		memcpy(str, &bson_numstrs[i], 4);
	else
		sprintf(str, "%d", i);
}
