module mongo_h;

import bson_h;

private import std.socket;

public static string mongo_error_str[] = ["Connection success!","Could not create a socket.",
                "An error occured while calling connect().","An error occured while calling getaddrinfo().",
                "Warning: connected to a non-master node (read-only).","Given rs name doesn't match this replica set.",
                "Can't find primary _in replica set. Connection closed.",
                "An error occurred while reading or writing on socket.","The response is not the expected length.",
                "The command returned with 'ok' value of 0.","The cursor has no more results.",
                "The cursor has timed _out or is not recognized.","Tailable cursor still alive but no data.",
                "BSON not valid for the specified op.","BSON object has not been finished."];

/**
 * @file mongo.h
 * @brief Main MongoDB Declarations
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

//#ifndef _MONGO_H_
//#define _MONGO_H_

//#include "bson.h"

//MONGO_EXTERN_C_START

public static byte MONGO_MAJOR = 0;
public static byte MONGO_MINOR= 4;
public static byte MONGO_PATCH= 0;

public static byte MONGO_OK= 0;
public static byte MONGO_ERROR= -1;

public static int MONGO_DEFAULT_PORT= 27017;

enum mongo_error_t {
    MONGO_CONN_SUCCESS = 0,  /**< Connection success! */
    MONGO_CONN_NO_SOCKET,    /**< Could not create a socket. */
    MONGO_CONN_FAIL,         /**< An error occured while calling connect(). */
    MONGO_CONN_ADDR_FAIL,    /**< An error occured while calling getaddrinfo(). */
    MONGO_CONN_NOT_MASTER,   /**< Warning: connected to a non-master node (read-only). */
    MONGO_CONN_BAD_SET_NAME, /**< Given rs name doesn't match this replica set. */
    MONGO_CONN_NO_PRIMARY,   /**< Can't find primary _in replica set. Connection closed. */

    MONGO_IO_ERROR,          /**< An error occurred while reading or writing on socket. */
    MONGO_READ_SIZE_ERROR,   /**< The response is not the expected length. */
    MONGO_COMMAND_FAILED,    /**< The command returned with 'ok' value of 0. */
    MONGO_CURSOR_EXHAUSTED,  /**< The cursor has no more results. */
    MONGO_CURSOR_INVALID,    /**< The cursor has timed _out or is not recognized. */
    MONGO_CURSOR_PENDING,    /**< Tailable cursor still alive but no data. */
    MONGO_BSON_INVALID,      /**< BSON not valid for the specified op. */
    MONGO_BSON_NOT_FINISHED  /**< BSON object has not been finished. */
} ;

enum  {
    MONGO_CURSOR_MUST_FREE = 1,      /**< mongo_cursor_destroy should free cursor. */
    MONGO_CURSOR_QUERY_SENT = ( 1<<1 ) /**< Initial query has been sent. */
};

enum  {
    MONGO_INDEX_UNIQUE = ( 1<<0 ),
    MONGO_INDEX_DROP_DUPS = ( 1<<2 ),
    MONGO_INDEX_BACKGROUND = ( 1<<3 ),
    MONGO_INDEX_SPARSE = ( 1<<4 )
};

enum  {
    MONGO_UPDATE_UPSERT = 0x1,
    MONGO_UPDATE_MULTI = 0x2,
    MONGO_UPDATE_BASIC = 0x4
};

enum mongo_cursor_opts {
    MONGO_TAILABLE = ( 1<<1 ),        /**< Create a tailable cursor. */
    MONGO_SLAVE_OK = ( 1<<2 ),        /**< Allow queries on a non-primary node. */
    MONGO_NO_CURSOR_TIMEOUT = ( 1<<4 ), /**< Disable cursor timeouts. */
    MONGO_AWAIT_DATA = ( 1<<5 ),      /**< Momentarily block for more data. */
    MONGO_EXHAUST = ( 1<<6 ),         /**< Stream _in multiple 'more' packages. */
    MONGO_PARTIAL = ( 1<<7 )          /**< Allow reads even if a shard is down. */
};

enum  {
    MONGO_OP_MSG = 1000,
    MONGO_OP_UPDATE = 2001,
    MONGO_OP_INSERT = 2002,
    MONGO_OP_QUERY = 2004,
    MONGO_OP_GET_MORE = 2005,
    MONGO_OP_DELETE = 2006,
    MONGO_OP_KILL_CURSORS = 2007
};

//#pragma pack(1)
struct mongo_header{
    int len;
    int id;
    int responseTo;
    int op;
};

struct mongo_message{
    mongo_header head;
    char data;
} ;

struct mongo_reply_fields{
    int flag; /* FIX THIS COMMENT non-zero on failure */
    int64_t cursorID;
    int start;
    int num;
} ;

struct mongo_reply{
    mongo_header head;
    mongo_reply_fields fields;
    char objs;
} ;
//#pragma pack()

struct mongo_host_port {
    string host;
    int port;
    mongo_host_port *next;
} ;

struct mongo_replset{
    mongo_host_port *seeds;        /**< List of seeds provided by the user. */
    mongo_host_port *hosts;        /**< List of host/ports given by the replica set */
    char *name;                    /**< Name of the replica set. */
    bson_bool_t primary_connected; /**< Primary node connection status. */
} ;

struct mongo {
    mongo_host_port *primary;  /**< Primary connection info. */
    mongo_replset *replset;    /**< replset object if connected to a replica set. */
    Socket sock;                  /**< Socket file descriptor. */
    int flags;                 /**< Flags on this connection object. */
    int conn_timeout_ms;       /**< Connection timeout _in milliseconds. */
    int op_timeout_ms;         /**< Read and write timeout _in milliseconds. */
    bson_bool_t connected;     /**< Connection status. */

    mongo_error_t err;         /**< Most recent driver error code. */
    char *errstr;              /**< String version of most recent driver error code. */
    int lasterrcode;           /**< getlasterror given by the server on calls. */
    char *lasterrstr;          /**< getlasterror string generated by server. */
} ;

struct mongo_cursor{
    mongo_reply *reply;  /**< reply is owned by cursor */
    mongo *conn;       /**< connection is *not* owned by cursor */
     char *ns;    /**< owned by cursor */
    int flags;         /**< Flags used internally by this drivers. */
    int seen;          /**< Number returned so far. */
    bson current;      /**< This cursor's current bson object. */
    mongo_error_t err; /**< Errors on this cursor. */
    bson *query;       /**< Bitfield containing cursor options. */
    bson *fields;      /**< Bitfield containing cursor options. */
    int options;       /**< Bitfield containing cursor options. */
    int limit;         /**< Bitfield containing cursor options. */
    int skip;          /**< Bitfield containing cursor options. */
} ;


