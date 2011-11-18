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
int INT_MAX =  32767;

/**
 * @file bson.h
 * @brief BSON Declarations
 */

/*    Copyright 2009-2011 10gen Inc.
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

//#ifndef _BSON_H_
//#define _BSON_H_

//#include "platform.h"
//#include <time.h>
//#include <stdlib.h>
//#include <string.h>
//#include <stdio.h>
//#include <stdarg.h>

//MONGO_EXTERN_C_START

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

//#pragma pack(1)
union bson_oid_t{
    char bytes[12];
    int ints[3];
} ;
//#pragma pack()

alias int64_t bson_date_t; /* milliseconds since epoch UTC */

struct bson_timestamp_t{
    int i; /* increment */
    int t; /* time _in seconds */
} ;

