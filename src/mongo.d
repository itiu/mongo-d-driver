/* mongo.c */

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
/*
Copyright (C) 2004 Christopher E. Miller

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgment in the product documentation would be
   appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.

*/

/*******************************************************************************

copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

license:        BSD style: $(LICENSE)

version:        Initial release: March 2004

author:         Christopher Miller
                Kris Bell
                Anders F Bjorklund (Darwin patches)


The original code has been modified in several ways:
        
1) It has been altered to fit within the Tango environment, meaning
   that certain original classes have been reorganized, and/or have
   subclassed Tango base-classes. For example, the original Socket
   class has been wrapped with three distinct subclasses, and now
   derives from class tango.io.Resource.

2) All exception instances now subclass the Tango IOException.

3) Construction of new Socket instances via accept() is now
   overloadable.

4) Constants and enums have been moved within a class boundary to
   ensure explicit namespace usage.

5) changed Socket.select() to loop if it was interrupted.


All changes within the main body of code all marked with "Tango:"

For a good tutorial on socket-programming I highly recommend going
here: http://www.ecst.csuchico.edu/~beej/guide/net/

*******************************************************************************/

import md5;
import bson;

private import std.c.stdlib;
private import std.c.string;
private import std.intrinsic;
private import std.stdio;

/*
version (D2)
{
    alias const char const_char;
    private import core.sys.posix.setjmp1;
    alias setjmp1 setJMP;
}
version (D1)
{
    alias char const_char;
    alias setjmp setJMP;
}
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
alias int bson_bool_t;

alias byte int8_t;
alias ubyte uint8_t;

alias short int16_t;
alias ushort uint16_t;

alias int int32_t;
alias uint uint32_t;

alias long int64_t;
alias ulong uint64_t;

public const static byte MONGO_MAJOR = 0;
public const static byte MONGO_MINOR = 4;
public const static byte MONGO_PATCH = 0;

public const static byte MONGO_OK = BSON_OK;
public const static byte MONGO_ERROR = BSON_ERROR;

public const static byte MONGO_IO_ERROR = 1;
public const static byte MONGO_READ_SIZE_ERROR = 2;
public const static byte MONGO_COMMAND_FAILED = 3;
public const static byte MONGO_CURSOR_EXHAUSTED = 4;
public const static byte MONGO_CURSOR_INVALID = 5;
public const static byte MONGO_INVALID_BSON = 6; /**< BSON not valid for the specified op. */

/* Cursor bitfield options. */
public const static int MONGO_TAILABLE = (1<<1); /**< Create a tailable cursor. */
public const static int MONGO_SLAVE_OK = (1<<2); /**< Allow queries on a non-primary node. */
public const static int MONGO_NO_CURSOR_TIMEOUT = (1<<4); /**< Disable cursor timeouts. */
public const static int MONGO_AWAIT_DATA = (1<<5); /**< Momentarily block at end of query for more data. */
public const static int MONGO_EXHAUST = (1<<6);    /**< Stream data in multiple 'more' packages. */
public const static int MONGO_PARTIAL = (1<<7); /**< Via mongos, allow reads even if a shard is down. */


struct mongo_host_port 
{
    char host[255];
    int port;
    mongo_host_port* next;
};

struct mongo_replset
{
    mongo_host_port* seeds; /**< The list of seed nodes provided by the user. */
    mongo_host_port* hosts; /**< The list of host and ports reported by the replica set */
    char* name;             /**< The name of the replica set. */
    bson_bool_t primary_connected; /**< Whether we've managed to connect to a primary node. */
};

struct mongo_connection
{
    mongo_host_port* primary;
    mongo_replset* replset;
    socket_t sock;
    bson_bool_t connected;
    int err; /**< Most recent driver error code. */
    char* errstr; /**< String version of most recent driver error code, if applicable. */
    int lasterrcode; /**< Error code generated by the core server on calls to getlasterror. */
    char* lasterrstr; /**< Error string generated by server on calls to getlasterror. */
};

struct mongo_header
{
    int len;
    int id;
    int responseTo;
    int op;
};

struct mongo_message
{
    mongo_header head;
    char data;
};

struct mongo_reply_fields
{
    int flag; /* non-zero on failure */
    int64_t cursorID;
    int start;
    int num;
};

struct mongo_reply
{
    mongo_header head;
    mongo_reply_fields fields;
    char objs;
};

struct mongo_cursor
{
    mongo_reply * mm; /* message is owned by cursor */
    mongo_connection * conn; /* connection is *not* owned by cursor */
    char* ns; /* owned by cursor */
    bson current;
};

enum: int
{
    mongo_op_msg = 1000,    /* generic msg command followed by a string */
    mongo_op_update = 2001, /* update object */
    mongo_op_insert = 2002,
    mongo_op_query = 2004,
    mongo_op_get_more = 2005,
    mongo_op_delete = 2006,
    mongo_op_kill_cursors = 2007
};


/*
 * CONNECTIONS
 */
enum: int 
{
    mongo_conn_success = 0,
    mongo_conn_bad_arg,
    mongo_conn_no_socket,
    mongo_conn_fail,
    mongo_conn_not_master, /* leaves conn connected to slave */
    mongo_conn_bad_set_name, /* The provided replica set name doesn't match the existing replica set */
    mongo_conn_cannot_find_primary
};

static const int MONGO_UPDATE_UPSERT = 0x1;
static const int MONGO_UPDATE_MULTI = 0x2;

static const int MONGO_INDEX_UNIQUE = 0x1;
static const int MONGO_INDEX_DROP_DUPS = 0x2;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Standard well-defined IP protocols.  */
enum
  {
    IPPROTO_IP = 0,        /* Dummy protocol for TCP.  */
    IPPROTO_HOPOPTS = 0,   /* IPv6 Hop-by-Hop options.  */
    IPPROTO_ICMP = 1,      /* Internet Control Message Protocol.  */
    IPPROTO_IGMP = 2,      /* Internet Group Management Protocol. */
    IPPROTO_IPIP = 4,      /* IPIP tunnels (older KA9Q tunnels use 94).  */
    IPPROTO_TCP = 6,       /* Transmission Control Protocol.  */
    IPPROTO_EGP = 8,       /* Exterior Gateway Protocol.  */
    IPPROTO_PUP = 12,      /* PUP protocol.  */
    IPPROTO_UDP = 17,      /* User Datagram Protocol.  */
    IPPROTO_IDP = 22,      /* XNS IDP protocol.  */
    IPPROTO_TP = 29,       /* SO Transport Protocol Class 4.  */
    IPPROTO_DCCP = 33,     /* Datagram Congestion Control Protocol.  */
    IPPROTO_IPV6 = 41,     /* IPv6 header.  */
    IPPROTO_ROUTING = 43,  /* IPv6 routing header.  */
    IPPROTO_FRAGMENT = 44, /* IPv6 fragmentation header.  */
    IPPROTO_RSVP = 46,     /* Reservation Protocol.  */
    IPPROTO_GRE = 47,      /* General Routing Encapsulation.  */
    IPPROTO_ESP = 50,      /* encapsulating security payload.  */
    IPPROTO_AH = 51,       /* authentication header.  */
    IPPROTO_ICMPV6 = 58,   /* ICMPv6.  */
    IPPROTO_NONE = 59,     /* IPv6 no next header.  */
    IPPROTO_DSTOPTS = 60,  /* IPv6 destination options.  */
    IPPROTO_MTP = 92,      /* Multicast Transport Protocol.  */
    IPPROTO_ENCAP = 98,    /* Encapsulation Header.  */
    IPPROTO_PIM = 103,     /* Protocol Independent Multicast.  */
    IPPROTO_COMP = 108,    /* Compression Header Protocol.  */
    IPPROTO_SCTP = 132,    /* Stream Control Transmission Protocol.  */
    IPPROTO_UDPLITE = 136, /* UDP-Lite protocol.  */
    IPPROTO_RAW = 255,     /* Raw IP packets.  */
    IPPROTO_MAX
  };

  enum
  {
          TCP_NODELAY = 1,                /* Turn off Nagle's algorithm. */
          TCP_MAXSEG = 2,                 /* Limit MSS */
          TCP_CORK = 3,                   /* Never send partially complete segments */
          TCP_KEEPIDLE = 4,               /* Start keeplives after this period */
          TCP_KEEPINTVL = 5,              /* Interval between keepalives */
          TCP_KEEPCNT = 6,                /* Number of keepalives before death */
          TCP_SYNCNT = 7,                 /* Number of SYN retransmits */
          TCP_LINGER2 = 8,                /* Life time of orphaned FIN-WAIT-2 state */
          TCP_DEFER_ACCEPT = 9,   /* Wake up listener only when data arrive */
          TCP_WINDOW_CLAMP = 10,  /* Bound advertised window */
          TCP_INFO = 11,                  /* Information about this connection. */
          TCP_QUICKACK = 12,              /* Block/reenable quick acks */
          TCP_CONGESTION = 13,    /* Congestion control algorithm */
          TCP_MD5SIG = 14                 /* TCP MD5 Signature (RFC2385) */
  };


enum: int
{
	AF_UNSPEC = 0,
	AF_UNIX = 1,
	AF_INET = 2,
	AF_IPX = 4,
	AF_APPLETALK = 5,
	AF_INET6 = 10,
	// ...

	PF_UNSPEC = AF_UNSPEC,
	PF_UNIX = AF_UNIX,
	PF_INET = AF_INET,
	PF_IPX = AF_IPX,
	PF_APPLETALK = AF_APPLETALK,
	PF_INET6 = AF_INET6,
}

extern(C)
	struct sockaddr_in
	{
		int16_t sin_family = AF_INET;
		uint16_t sin_port;
		in_addr sin_addr;
		ubyte[8] sin_zero;
	};

	alias uint32_t in_addr_t;

	extern (C)
	struct sockaddr
	{
	  ushort sa_family;
	  ubyte sa_data[14];
	};

	extern(C)
    union in_addr
    {
            private union _S_un_t
            {
                    private struct _S_un_b_t
                    {
                            uint8_t s_b1, s_b2, s_b3, s_b4;
                    }

                    _S_un_b_t S_un_b;

                    private struct _S_un_w_t
                    {
                            uint16_t s_w1, s_w2;
                    }

                    _S_un_w_t S_un_w;

                    uint32_t S_addr;
            }               

            _S_un_t S_un;

            uint32_t s_addr;

            struct
            {
                    uint8_t s_net, s_host;

                    union
                    {
                            uint16_t s_imp;

                            struct
                            {
                                    uint8_t s_lh, s_impno;
                            }
                    }
            }
    }

	alias int ssize_t;

	version (linux)
	{
	extern(C)
	        ssize_t send(int __fd, void* __buf, size_t __n, int __flags);
	    
	extern (C) ssize_t recv (int __fd, void *__buf, size_t __n, int __flags);
	}
	
	enum socket_type
	{
	  SOCK_STREAM = 1,              /* Sequenced, reliable, connection-based
	                                   byte streams.  */
	  SOCK_DGRAM = 2,               /* Connectionless, unreliable datagrams
	                                   of fixed maximum length.  */
	  SOCK_RAW = 3,                 /* Raw protocol interface.  */
	  SOCK_RDM = 4,                 /* Reliably-delivered messages.  */
	  SOCK_SEQPACKET = 5,           /* Sequenced, reliable, connection-based,
	                                   datagrams of fixed maximum length.  */
	  SOCK_DCCP = 6,                /* Datagram Congestion Control Protocol.  */
	  SOCK_PACKET = 10,             /* Linux specific way of getting packets
	                                   at the dev level.  For writing rarp and
	                                   other similar things on the user level. */

	  /* Flags to be ORed into the type parameter of socket and socketpair and
	     used for the flags parameter of paccept.  */

	  SOCK_CLOEXEC = std.conv.octal!2000000,      /* Atomically set close-on-exec flag for the
	                                   new descriptor(s).  */
	  SOCK_NONBLOCK = std.conv.octal!4000         /* Atomically mark descriptor(s) as
	                                   non-blocking.  */
	};
	
	version (Win32)
	{
	   pragma(lib, "ws2_32.lib");

	   extern  (Windows)
	   {
		  private typedef int socket_t = ~0;
		   
	      int send(int s, void* buf, int len, int flags);
	      int recv(int s, void* buf, int len, int flags);
	      int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
	      uint inet_addr(const char* cp);
	      int connect(socket_t s, sockaddr* name, socklen_t namelen);
	      socket_t socket(int af, int type, int protocol);
	   }

	   private typedef int socklen_t; // __STD_TYPE __U32_TYPE __socklen_t;
	}

	version (linux)
	{
	    private typedef int socket_t = ~0;
	    
	    extern (C) int socket (int __domain, int __type, int __protocol);	
	    private typedef int socklen_t; // __STD_TYPE __U32_TYPE __socklen_t;
	    extern (C) in_addr_t inet_addr (const char *__cp);
	    extern (C) int connect (socket_t __fd, sockaddr * __addr, socklen_t __len);
	    extern (C) int setsockopt (int __fd, int __level, int __optname, void *__optval, socklen_t __optlen);
	}
	
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* only need one of these */
static const int zero = 0;
static const int one = 1;

/* ----------------------------
   message stuff
   ------------------------------ */

static int looping_write(mongo_connection * conn, const void* buf, int len)
{
    char* cbuf = cast (char*)buf;

    while (len)
	{
    	int sent = send(conn.sock, cbuf, len, 0);
	
        if (sent == -1)
        {
	    writeln ("MONGO_IO_ERROR");
           return MONGO_IO_ERROR;
        }
        cbuf += sent;
        len -= sent;
    }

    return MONGO_OK;
}

static int looping_read(mongo_connection * conn, void* buf, int len){
    char* cbuf = cast (char*)buf;
    while (len){
        int sent = recv(conn.sock, cbuf, len, 0);
        if (sent == 0 || sent == -1)
            return MONGO_IO_ERROR;
        cbuf += sent;
        len -= sent;
    }

    return MONGO_OK;
}

/* Always calls free(mm) */
int mongo_message_send(mongo_connection * conn, mongo_message* mm){
    mongo_header head; /* little endian */
    int res;
    bson_little_endian32(&head.len, &mm.head.len);
    bson_little_endian32(&head.id, &mm.head.id);
    bson_little_endian32(&head.responseTo, &mm.head.responseTo);
    bson_little_endian32(&head.op, &mm.head.op);

    res = looping_write(conn, &head, head.sizeof);
    if( res != MONGO_OK ) {
        free( mm );
        return res;
    }

    res = looping_write(conn, &mm.data, mm.head.len - head.sizeof);
    if( res != MONGO_OK ) {
        free( mm );
        return res;
    }

    free( mm );
    return MONGO_OK;
}

char * mongo_data_append( char * start , const void * data , int len ){
    memcpy( start , data , len );
    return start + len;
}

char * mongo_data_append32( char * start , const void * data){
    bson_little_endian32( start , data );
    return start + 4;
}

char * mongo_data_append64( char * start , const void * data){
    bson_little_endian64( start , data );
    return start + 8;
}

mongo_message * mongo_message_create( int len , int id , int responseTo , int op ){
    mongo_message * mm = cast(mongo_message*)bson_malloc( len );

    if (!id)
        id = rand();

    /* native endian (converted on send) */
    mm.head.len = len;
    mm.head.id = id;
    mm.head.responseTo = responseTo;
    mm.head.op = op;

    return mm;
}

/* ----------------------------
   connection stuff
   ------------------------------ */
 void mongo_close_socket (int sock) 
 {
     //#ifdef _WIN32
     version (windows)
     {
     closesocket(conn.sock);
     }
     else
     {
     //#else
//@@@@????      close(conn.sock);
     //#endif
     }
 }

version (_MONGO_USE_GETADDRINFO)
{
static int mongo_socket_connect( mongo_connection * conn, const char * host, int port ){

    addrinfo* addrs = null;
    addrinfo hints;
    char port_str[12];
    int ret;

    conn.sock = 0;
    conn.connected = 0;

    memset( &hints, 0, hints.sizeof);
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    sprintf( port_str, "%d", port );

    conn.sock = socket( AF_INET, SOCK_STREAM, 0 );
    if ( conn.sock < 0 ){
        printf("Socket: %d", conn.sock);
        mongo_close_socket( conn.sock );
        return mongo_conn_no_socket;
    }

    ret = getaddrinfo( host, port_str, &hints, &addrs );
    if(ret) {
        fprintf( stderr, "getaddrinfo failed: %s", gai_strerror( ret ) );
        return mongo_conn_fail;
    }

    if ( connect( conn.sock, addrs.ai_addr, addrs.ai_addrlen ) ){
        mongo_close_socket( conn.sock );
        freeaddrinfo( addrs );
        return mongo_conn_fail;
    }

    setsockopt( conn.sock, IPPROTO_TCP, TCP_NODELAY, cast(char *) &one, one.sizeof );

    conn.connected = 1;
    freeaddrinfo( addrs );
    return MONGO_OK;
}
}
else
{
static int mongo_socket_connect( mongo_connection * conn, const char * host, int port ){
    sockaddr_in sa;
    socklen_t addressSize;

    memset( sa.sin_zero.ptr , 0 , sa.sin_zero.sizeof );
    sa.sin_family = AF_INET;
    sa.sin_port = htons( cast(ushort)port );
    sa.sin_addr.s_addr = inet_addr( host );
    addressSize = sa.sizeof;

    conn.sock = cast (socket_t)socket( AF_INET, socket_type.SOCK_STREAM, 0 );
    if ( conn.sock < 0 ){
        mongo_close_socket( conn.sock );
        return mongo_conn_no_socket;
    }

    if ( connect( conn.sock, cast(sockaddr *)&sa, addressSize ) ){
        return mongo_conn_fail;
    }

    setsockopt( conn.sock, IPPROTO_TCP, TCP_NODELAY, cast(char *) &one, one.sizeof );

    conn.connected = 1;
    return MONGO_OK;
}
}

int mongo_connect( mongo_connection * conn , const char * host, int port ){
    conn.replset = null;

    conn.primary = cast (mongo_host_port*)bson_malloc(  mongo_host_port.sizeof );

    strncpy( conn.primary.host.ptr	, host, strlen( host ) + 1 );
    conn.primary.port = port;
    conn.primary.next = null;

    conn.err = 0;
    conn.errstr = null;
    conn.lasterrcode = 0;
    conn.lasterrstr = null;

    return mongo_socket_connect(conn, host, port);
}

void mongo_replset_init_conn( mongo_connection* conn, const char* name ) {
    conn.replset = cast(mongo_replset*)bson_malloc( mongo_replset.sizeof );
    conn.replset.primary_connected = 0;
    conn.replset.seeds = null;
    conn.replset.hosts = null;
    conn.replset.name = cast(char *)bson_malloc( strlen( name ) + 1 );
    memcpy( conn.replset.name, name, strlen( name ) + 1  );

    conn.primary = cast(mongo_host_port*)bson_malloc( mongo_host_port.sizeof );

    conn.err = 0;
    conn.errstr = null;
    conn.lasterrcode = 0;
    conn.lasterrstr = null;
}

static int mongo_replset_add_node( mongo_host_port** list, const char* host, int port ) {
    mongo_host_port* host_port = cast (mongo_host_port*)bson_malloc( mongo_host_port.sizeof);
    host_port.port = port;
    host_port.next = null;
    strncpy( host_port.host.ptr, host, strlen(host) + 1 );

    if( *list == null )
        *list = host_port;
    else {
        mongo_host_port* p = *list;
        while( p.next != null )
          p = p.next;
        p.next = host_port;
    }

    return MONGO_OK;
}

static int mongo_replset_free_list( mongo_host_port** list ) {
    mongo_host_port* node = *list;
    mongo_host_port* prev;

    while( node != null ) {
        prev = node;
        node = node.next;
        free(prev);
    }

    *list = null;
    return MONGO_OK;
}

int mongo_replset_add_seed(mongo_connection* conn, const char* host, int port) {
    return mongo_replset_add_node( &conn.replset.seeds, host, port );
}

static void mongo_parse_host( const char *host_string, mongo_host_port *host_port ) {
    int len, idx, split;
    len = split = idx = 0;

    /* Split the host_port string at the ':' */
    while(1) {
        if( *(host_string + len) == '\0' )
          break;
        if( *(host_string + len) == ':' )
          split = len;

        len++;
    }

    /* If 'split' is set, we know the that port exists;
     * Otherwise, we set the default port.
     */
    idx = split ? split : len;
    memcpy( host_port.host.ptr, host_string, idx );
    memcpy( host_port.host.ptr + idx, cast(char*)"\0", 1 );
    if( split )
        host_port.port = atoi( host_string + idx + 1 );
    else
        host_port.port = 27017;
}

static int mongo_replset_check_seed( mongo_connection* conn ) {
    bson _out;
    bson hosts;
    char* data;
    bson_iterator it;
    bson_iterator it_sub;
    char* host_string;
    char* host;
    int len, idx, port, split;
    mongo_host_port *host_port = null;

    _out.data = null;
    _out.owned = 1;

    hosts.data = null;
    hosts.owned = 1;

    if( mongo_simple_int_command(conn, "admin", "ismaster", 1, &_out) == MONGO_OK ) {

        if( bson_find( &it, &_out, cast(char*)"hosts" ) ) {
            data = bson_iterator_value( &it );
            bson_iterator_init( &it_sub, data );

            /* Iterate over host list, adding each host to the
             * connection's host list. */
            while( bson_iterator_next( &it_sub ) ) {
                host_string = bson_iterator_string( &it_sub );

                host_port = cast (mongo_host_port*)bson_malloc(mongo_host_port.sizeof);
                mongo_parse_host( host_string, host_port );

                if( host_port ) {
                    mongo_replset_add_node( &conn.replset.hosts,
                        host_port.host.ptr, host_port.port );

                    free( host_port );
                    host_port = null;
                }
            }
        }
    }

    bson_destroy( &_out );
    bson_destroy( &hosts );
    mongo_close_socket( conn.sock );
    conn.sock = 0;
    conn.connected = 0;

    return 0;
}

/* Find out whether the current connected node is master, and
 * verify that the node's replica set name matched the provided name
 */
static int mongo_replset_check_host( mongo_connection* conn ) {

    bson _out;
    bson_iterator it;
    bson_bool_t ismaster = 0;
    char* set_name;

    _out.data = null;
    _out.owned = 1;

    if (mongo_simple_int_command(conn, "admin", "ismaster", 1, &_out) == MONGO_OK) {
        if( bson_find(&it, &_out, cast(char*)"ismaster") )
            ismaster = bson_iterator_bool( &it );

        if( bson_find( &it, &_out, cast(char*)"setName") ) {
            set_name = bson_iterator_string( &it );
            if( strcmp( set_name, conn.replset.name ) != 0 ) {
                bson_destroy( &_out );
                return mongo_conn_bad_set_name;
            }
        }
    }

    bson_destroy( &_out );

    if(ismaster) {
        conn.replset.primary_connected = 1;
    }
    else {
        mongo_close_socket( conn.sock );
    }

    return 0;
}

int mongo_replset_connect(mongo_connection* conn) {

    int connect_error = 0;
    mongo_host_port* node;

    conn.sock = 0;
    conn.connected = 0;

    /* First iterate over the seed nodes to get the canonical list of hosts
     * from the replica set. Break out once we have a host list.
     */
    node = conn.replset.seeds;
    while( node != null ) {
        connect_error = mongo_socket_connect( conn, cast(const char*)&node.host, node.port );

        if( connect_error == 0 ) {
        	connect_error = mongo_replset_check_seed( conn );
            if (connect_error)
                return connect_error;
        }

        if( conn.replset.hosts )
            break;

        node = node.next;
    }

    /* Iterate over the host list, checking for the primary node. */
    if( !conn.replset.hosts ) {
        return mongo_conn_cannot_find_primary;
    }
    else {
        node = conn.replset.hosts;

        while( node != null ) {
            connect_error = mongo_socket_connect( conn, cast(const char*)&node.host, node.port );

            if( connect_error == 0 ) {
            	connect_error = mongo_replset_check_host( conn );
                if ( connect_error )
                    return connect_error;

                /* Primary found, so return. */
                else if( conn.replset.primary_connected )
                     return 0;

                /* No primary, so close the connection. */
                else {
                    mongo_close_socket( conn.sock );
                    conn.sock = 0;
                    conn.connected = 0;
                }
            }

            node = node.next;
        }
    }

    return mongo_conn_cannot_find_primary;
}

int mongo_reconnect( mongo_connection * conn ){
    int res;
    mongo_disconnect(conn);

    if( conn.replset ) {
        conn.replset.primary_connected = 0;
        mongo_replset_free_list( &conn.replset.hosts );
        conn.replset.hosts = null;
        res = mongo_replset_connect( conn );
        return res;
    }
    else
        return mongo_socket_connect( conn, conn.primary.host.ptr, conn.primary.port );
}

bson_bool_t mongo_disconnect( mongo_connection * conn ){
    if( ! conn.connected )
        return 1;

    if( conn.replset ) {
        conn.replset.primary_connected = 0;
        mongo_replset_free_list( &conn.replset.hosts );
        conn.replset.hosts = null;
        return mongo_replset_connect( conn );
    }

    mongo_close_socket( conn.sock );

    conn.sock = 0;
    conn.connected = 0;

    return 0;
}

bson_bool_t mongo_destroy( mongo_connection * conn ){
    if( conn.replset ) {
        mongo_replset_free_list( &conn.replset.seeds );
        mongo_replset_free_list( &conn.replset.hosts );
        free( conn.replset.name );
        free( conn.replset );
        conn.replset = null;
    }

    free( conn.primary );
    free( conn.errstr );
    free( conn.lasterrstr );

    conn.err = 0;
    conn.errstr = null;
    conn.lasterrcode = 0;
    conn.lasterrstr = null;

    return mongo_disconnect( conn );
}

/*
 * Determine whether this BSON object is valid for the
 * given operation.
 */
static int mongo_bson_valid( mongo_connection * conn, const bson* bson, int write ) {
    if( bson.err & BSON_NOT_UTF8 ) {
        conn.err = MONGO_INVALID_BSON;
        return MONGO_ERROR;
    }

    if( write ) {
        if( (bson.err & BSON_FIELD_HAS_DOT) ||
            (bson.err & BSON_FIELD_INIT_DOLLAR) ) {

            conn.err = MONGO_INVALID_BSON;
            return MONGO_ERROR;

        }
    }

    conn.err = 0;
    conn.errstr = null;

    return MONGO_OK;
}

int mongo_insert_batch( mongo_connection * conn, const char * ns,
    bson ** bsons, int count ) {

    int size =  16 + 4 + strlen( ns ) + 1;
    int i;
    mongo_message * mm;
    char* data;

    for(i=0; i<count; i++){
        size += bson_size(bsons[i]);
        if( mongo_bson_valid( conn, bsons[i], 1 ) != MONGO_OK )
            return MONGO_ERROR;
    }

    mm = mongo_message_create( size , 0 , 0 , mongo_op_insert );

    data = &mm.data;
    data = mongo_data_append32(data, &zero);
    data = mongo_data_append(data, ns, strlen(ns) + 1);

    for(i=0; i<count; i++){
        data = mongo_data_append(data, bsons[i].data, bson_size( bsons[i] ) );
    }

    return mongo_message_send(conn, mm);
}

int mongo_insert( mongo_connection * conn , const char * ns , bson * bson ) {

    char* data;
    mongo_message* mm;

    /* Make sure that BSON is valid for insert. */
    if( mongo_bson_valid( conn, bson, 1 ) != MONGO_OK ) {
        return MONGO_ERROR;
    }

    mm = mongo_message_create( 16 /* header */
                              + 4 /* ZERO */
                              + strlen(ns)
                              + 1 + bson_size(bson)
                              , 0, 0, mongo_op_insert);

    data = &mm.data;
    data = mongo_data_append32(data, &zero);
    data = mongo_data_append(data, ns, strlen(ns) + 1);
    data = mongo_data_append(data, bson.data, bson_size(bson));

    return mongo_message_send(conn, mm);
}

int mongo_update(mongo_connection* conn, const char* ns, const bson* cond,
    const bson* op, int flags) {

    char* data;
    mongo_message* mm;

    /* Make sure that the op BSON is valid UTF-8.
     * TODO: decide whether to check cond as well.
     * */
    if( mongo_bson_valid( conn, op, 0 ) != MONGO_OK ) {
        return MONGO_ERROR;
    }

    mm = mongo_message_create( 16 /* header */
                              + 4  /* ZERO */
                              + strlen(ns) + 1
                              + 4  /* flags */
                              + bson_size(cond)
                              + bson_size(op)
                              , 0 , 0 , mongo_op_update );

    data = &mm.data;
    data = mongo_data_append32(data, &zero);
    data = mongo_data_append(data, ns, strlen(ns) + 1);
    data = mongo_data_append32(data, &flags);
    data = mongo_data_append(data, cond.data, bson_size(cond));
    data = mongo_data_append(data, op.data, bson_size(op));

    return mongo_message_send(conn, mm);
}

int mongo_remove(mongo_connection* conn, const char* ns, const bson* cond){
    char * data;
    mongo_message * mm = mongo_message_create( 16 /* header */
                                             + 4  /* ZERO */
                                             + strlen(ns) + 1
                                             + 4  /* ZERO */
                                             + bson_size(cond)
                                             , 0 , 0 , mongo_op_delete );

    data = &mm.data;
    data = mongo_data_append32(data, &zero);
    data = mongo_data_append(data, ns, strlen(ns) + 1);
    data = mongo_data_append32(data, &zero);
    data = mongo_data_append(data, cond.data, bson_size(cond));

    return mongo_message_send(conn, mm);
}

int mongo_read_response( mongo_connection * conn, mongo_reply** mm ){
    mongo_header head; /* header from network */
    mongo_reply_fields fields; /* header from network */
    mongo_reply *_out; /* native endian */
    uint len;
    int res;

    looping_read(conn, &head, head.sizeof);
    looping_read(conn, &fields, fields.sizeof);

    bson_little_endian32(&len, &head.len);

    if (len < head.sizeof+fields.sizeof || len > 64*1024*1024)
        return MONGO_READ_SIZE_ERROR;  /* most likely corruption */

    _out = cast(mongo_reply*)bson_malloc(len);

    _out.head.len = len;
    bson_little_endian32(&_out.head.id, &head.id);
    bson_little_endian32(&_out.head.responseTo, &head.responseTo);
    bson_little_endian32(&_out.head.op, &head.op);

    bson_little_endian32(&_out.fields.flag, &fields.flag);
    bson_little_endian64(&_out.fields.cursorID, &fields.cursorID);
    bson_little_endian32(&_out.fields.start, &fields.start);
    bson_little_endian32(&_out.fields.num, &fields.num);

    res = looping_read(conn, &_out.objs, len-head.sizeof-fields.sizeof);
    if( res != MONGO_OK ) {
        free(_out);
        return res;
    }

    *mm = _out;

    return MONGO_OK;
}

mongo_cursor* mongo_find(mongo_connection* conn, const char* ns, bson* query,
    bson* fields, int nToReturn, int nToSkip, int options) {

    int sl;
    int res;
    mongo_cursor* cursor; /* volatile due to longjmp in mongo exception handler */
    char * data;
    mongo_message * mm = mongo_message_create( 16 + /* header */
                                               4 + /*  options */
                                               strlen( ns ) + 1 + /* ns */
                                               4 + 4 + /* skip,return */
                                               bson_size( query ) +
                                               bson_size( fields ) ,
                                               0 , 0 , mongo_op_query );


    data = &mm.data;
    data = mongo_data_append32( data , &options );
    data = mongo_data_append( data , ns , strlen( ns ) + 1 );
    data = mongo_data_append32( data , &nToSkip );
    data = mongo_data_append32( data , &nToReturn );
    data = mongo_data_append( data , query.data , bson_size( query ) );
    if ( fields )
        data = mongo_data_append( data , fields.data , bson_size( fields ) );

    bson_fatal_msg( (data == (cast(char*)mm) + mm.head.len), cast (char*)"query building fail!" );

    res = mongo_message_send( conn , mm );
    if(res != MONGO_OK){    
        conn.err = res;
        return null;
    }

    cursor = cast(mongo_cursor*)bson_malloc(mongo_cursor.sizeof);

    res = mongo_read_response( conn, &(cursor.mm) );
    if( res != MONGO_OK ) {
        conn.err = res;
        free(cast(mongo_cursor*)cursor); /* cast away volatile, not changing type */
        return null;
    }

    sl = strlen(ns)+1;
    cursor.ns = cast(char*)bson_malloc(sl);
    if (!cursor.ns){
        free(cursor.mm);
        free(cast(mongo_cursor*)cursor); /* cast away volatile, not changing type */
        return null;
    }
    memcpy(cast(void*)cursor.ns, ns, sl); /* cast needed to silence GCC warning */
    cursor.conn = conn;
    cursor.current.data = null;

    return cast(mongo_cursor*)cursor;
}

int mongo_find_one(mongo_connection* conn, const char* ns, bson* query,
    bson* fields, bson* _out) {

    mongo_cursor* cursor = mongo_find(conn, ns, query, fields, 1, 0, 0);

    if (cursor && mongo_cursor_next(cursor) == MONGO_OK){
        bson_copy(_out, &cursor.current);
        mongo_cursor_destroy(cursor);
        return MONGO_OK;
    } else{
        mongo_cursor_destroy(cursor);
        return MONGO_ERROR;
    }
}

int64_t mongo_count(mongo_connection* conn, const char* db, const char* ns, bson* query){
    bson_buffer bb;
    bson cmd;
    bson _out;
    int64_t count = -1;

    bson_buffer_init(&bb);
    bson_append_string(&bb, cast(char*)"count", ns);
    if (query && bson_size(query) > 5) /* not empty */
        bson_append_bson(&bb, cast(char*)"query", query);
    bson_from_buffer(&cmd, &bb);

    if( mongo_run_command(conn, db, &cmd, &_out) == MONGO_OK ) {
        bson_iterator it;
        if(bson_find(&it, &_out, cast(char*)"n"))
            count = bson_iterator_long(&it);
        bson_destroy(&cmd);
        bson_destroy(&_out);
        return count;
    }
    else {
        bson_destroy(&cmd);
        return MONGO_ERROR;
    }
}


int mongo_cursor_get_more(mongo_cursor* cursor){
    int res;

    if( ! cursor.mm.fields.cursorID)
        return MONGO_CURSOR_EXHAUSTED;
    else if( ! cursor.mm )
        return MONGO_CURSOR_INVALID;
    else {
        mongo_connection* conn = cursor.conn;
        char* data;
        int sl = strlen(cursor.ns)+1;
        mongo_message * mm = mongo_message_create(16 /*header*/
                                                 +4 /*ZERO*/
                                                 +sl
                                                 +4 /*numToReturn*/
                                                 +8 /*cursorID*/
                                                 , 0, 0, mongo_op_get_more);
        data = &mm.data;
        data = mongo_data_append32(data, &zero);
        data = mongo_data_append(data, cursor.ns, sl);
        data = mongo_data_append32(data, &zero);
        data = mongo_data_append64(data, &cursor.mm.fields.cursorID);

        res = mongo_message_send(conn, mm);
        if( res != MONGO_OK ) {
            cursor.mm = null;
            mongo_cursor_destroy(cursor);
            return res;
        }

        free(cursor.mm);

        res = mongo_read_response( cursor.conn, &(cursor.mm) );
        if( res != MONGO_OK ) {
            cursor.mm = null;
            mongo_cursor_destroy(cursor);
            return res;
        }

        return MONGO_OK;
    }
}

int mongo_cursor_next(mongo_cursor* cursor)
{
	if (cursor is null)
		return MONGO_ERROR;
	
	char* bson_addr;

    /* no data */
    if (!cursor.mm || cursor.mm.fields.num == 0) 
    {
        return MONGO_ERROR;
    }

    /* first */
    if (cursor.current.data == null){
        bson_init(&cursor.current, &cursor.mm.objs, 0);
        return MONGO_OK;
    }

    bson_addr = cursor.current.data + bson_size(&cursor.current);
    if (bson_addr >= (cast(char*)cursor.mm + cursor.mm.head.len)){
        if( mongo_cursor_get_more(cursor) != MONGO_OK )
            return MONGO_ERROR;
        bson_init(&cursor.current, &cursor.mm.objs, 0);
    } else {
    
        bson_init(&cursor.current, bson_addr, 0);
    }

    return MONGO_OK;
}

int mongo_cursor_destroy(mongo_cursor* cursor){
    int result = MONGO_OK;

    if (!cursor) return result;

    if (cursor.mm && cursor.mm.fields.cursorID){
        mongo_connection* conn = cursor.conn;
        mongo_message * mm = mongo_message_create(16 /*header*/
                                                 +4 /*ZERO*/
                                                 +4 /*numCursors*/
                                                 +8 /*cursorID*/
                                                 , 0, 0, mongo_op_kill_cursors);
        char* data = &mm.data;
        data = mongo_data_append32(data, &zero);
        data = mongo_data_append32(data, &one);
        data = mongo_data_append64(data, &cursor.mm.fields.cursorID);

        result = mongo_message_send(conn, mm);
    }

    free(cursor.mm);
    free(cast(void*)cursor.ns);
    free(cursor);

    return result;
}

int mongo_create_index(mongo_connection * conn, const char * ns, bson * key, int options, bson * _out){
    bson_buffer bb;
    bson b;
    bson_iterator it;
    char name[255] = ['_'];
    int i = 1;
    char idxns[1024];

    bson_iterator_init(&it, key.data);
    while(i < 255 && bson_iterator_next(&it)){
        strncpy(cast(char*)name + i, bson_iterator_key(&it), 255 - i);
        i += strlen(bson_iterator_key(&it));
    }
    name[254] = '\0';

    bson_buffer_init(&bb);
    bson_append_bson(&bb, cast(char*)"key", key);
    bson_append_string(&bb, cast(char*)"ns", ns);
    bson_append_string(&bb, cast(char*)"name", cast(char*)name);
    if (options & MONGO_INDEX_UNIQUE)
        bson_append_bool(&bb, cast(char*)"unique", 1);
    if (options & MONGO_INDEX_DROP_DUPS)
        bson_append_bool(&bb, cast(char*)"dropDups", 1);

    bson_from_buffer(&b, &bb);

    strncpy(cast(char*)idxns, ns, 1024-16);
    strcpy(strchr(cast(char*)idxns, '.'), cast(char*)".system.indexes");
    mongo_insert(conn, cast(char*)idxns, &b);
    bson_destroy(&b);

    *strchr(cast(char*)idxns, '.') = '\0'; /* just db not ns */
    return mongo_cmd_get_last_error(conn, cast(char*)idxns, _out);
}

bson_bool_t mongo_create_simple_index(mongo_connection * conn, const char * ns, const char* field, int options, bson * _out){
    bson_buffer bb;
    bson b;
    bson_bool_t success;

    bson_buffer_init(&bb);
    bson_append_int(&bb, field, 1);
    bson_from_buffer(&b, &bb);

    success = mongo_create_index(conn, ns, &b, options, _out);
    bson_destroy(&b);
    return success;
}

int mongo_run_command(mongo_connection* conn, const char* db, bson* command,
    bson* _out) {

    bson fields;
    int sl = strlen(db);
    char* ns = cast(char*)bson_malloc(sl + 5 + 1); /* ".$cmd" + nul */
    int res;

    strcpy(ns, db);
    strcpy(ns+sl, cast(char*)".$cmd");

    res = mongo_find_one(conn, ns, command, bson_empty(&fields), _out);
    free(ns);
    return res;
}

int mongo_simple_int_command(mongo_connection * conn, const char * db,
    const char* cmdstr, int arg, bson * realout) {

    bson _out;
    bson cmd;
    bson_buffer bb;
    bson_bool_t success = 0;

    bson_buffer_init(&bb);
    bson_append_int(&bb, cmdstr, arg);
    bson_from_buffer(&cmd, &bb);

    if( mongo_run_command(conn, db, &cmd, &_out) == MONGO_OK ){
        bson_iterator it;
        if(bson_find(&it, &_out, cast(char*)"ok"))
            success = bson_iterator_bool(&it);
    }

    bson_destroy(&cmd);

    if (realout)
        *realout = _out;
    else
        bson_destroy(&_out);

    if( success )
      return MONGO_OK;
    else {
      conn.err = MONGO_COMMAND_FAILED;
      return MONGO_ERROR;
    }
}

int mongo_simple_str_command(mongo_connection * conn, const char * db,
    const char* cmdstr, const char* arg, bson * realout) {

    bson _out;
    bson cmd;
    bson_buffer bb;
    int success = 0;

    bson_buffer_init(&bb);
    bson_append_string(&bb, cmdstr, arg);
    bson_from_buffer(&cmd, &bb);

    if( mongo_run_command(conn, db, &cmd, &_out) == MONGO_OK ) {
        bson_iterator it;
        if(bson_find(&it, &_out, cast(char*)"ok"))
            success = bson_iterator_bool(&it);
    }

    bson_destroy(&cmd);

    if (realout)
        *realout = _out;
    else
        bson_destroy(&_out);

    if(success)
      return MONGO_OK;
    else
      return MONGO_ERROR;
}

int mongo_cmd_drop_db(mongo_connection * conn, const char * db){
    return mongo_simple_int_command(conn, db, cast(char*)"dropDatabase", 1, null);
}

int mongo_cmd_drop_collection(mongo_connection * conn, const char * db, const char * collection, bson * _out){
    return mongo_simple_str_command(conn, db, cast(char*)"drop", collection, _out);
}

void mongo_cmd_reset_error(mongo_connection * conn, const char * db){
    mongo_simple_int_command(conn, db, cast(char*)"reseterror", 1, null);
}

static int mongo_cmd_get_error_helper(mongo_connection * conn, const char * db,
    bson * realout, const char * cmdtype) {

    bson _out = {null,0};
    bson_bool_t haserror = 0;

    /* Reset last error codes. */
    conn.lasterrcode = 0;
    free(conn.lasterrstr);
    conn.lasterrstr = null;

    /* If there's an error, store its code and string in the connection object. */
    if( mongo_simple_int_command(conn, db, cmdtype, 1, &_out) == MONGO_OK ) {
        bson_iterator it;
        haserror = (bson_find(&it, &_out, cast(char*)"err") != bson_type.bson_null);
        if( haserror ) {
             conn.lasterrstr = cast(char *)bson_malloc( bson_iterator_string_len( &it ) );
             if( conn.lasterrstr ) {
                 strcpy( conn.lasterrstr, bson_iterator_string( &it ) );
             }

            if( bson_find( &it, &_out, cast(char*)"code" ) != bson_type.bson_null )
                conn.lasterrcode = bson_iterator_int( &it );
        }
    }

    if(realout)
        *realout = _out; /* transfer of ownership */
    else
        bson_destroy(&_out);

    if( haserror )
        return MONGO_ERROR;
    else
        return MONGO_OK;
}

int mongo_cmd_get_prev_error(mongo_connection * conn, const char * db, bson * _out) {
    return mongo_cmd_get_error_helper(conn, db, _out, cast(char*)"getpreverror");
}

int mongo_cmd_get_last_error(mongo_connection * conn, const char * db, bson * _out) {
    return mongo_cmd_get_error_helper(conn, db, _out, cast(char*)"getlasterror");
}

bson_bool_t mongo_cmd_ismaster(mongo_connection * conn, bson * realout){
    bson _out = {null,0};
    bson_bool_t ismaster = 0;

    if (mongo_simple_int_command(conn, cast(char*)"admin", cast(char*)"ismaster", 1, &_out) == MONGO_OK){
        bson_iterator it;
        bson_find(&it, &_out, cast(char*)"ismaster");
        ismaster = bson_iterator_bool(&it);
    }

    if(realout)
        *realout = _out; /* transfer of ownership */
    else
        bson_destroy(&_out);

    return ismaster;
}

static void digest2hex(mongo_md5_byte_t digest[16], char hex_digest[33]){
    static const char hex[16] = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'];
    int i;
    for (i=0; i<16; i++){
        hex_digest[2*i]     = hex[(digest[i] & 0xf0) >> 4];
        hex_digest[2*i + 1] = hex[ digest[i] & 0x0f      ];
    }
    hex_digest[32] = '\0';
}

static void mongo_pass_digest(const char* user, const char* pass, char hex_digest[33]){
    mongo_md5_state_t st;
    mongo_md5_byte_t digest[16];

    mongo_md5_init(&st);
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)user, strlen(user));
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)":mongo:", 7);
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)pass, strlen(pass));
    mongo_md5_finish(&st, digest);
    digest2hex(digest, hex_digest);
}

int mongo_cmd_add_user(mongo_connection* conn, const char* db, const char* user, const char* pass){
    bson_buffer bb;
    bson user_obj;
    bson pass_obj;
    char hex_digest[33];
    char* ns = cast(char*)bson_malloc(strlen(db) + strlen(cast(char*)".system.users") + 1);
    int res;

    strcpy(ns, db);
    strcpy(ns+strlen(db), cast(char*)".system.users");

    mongo_pass_digest(user, pass, hex_digest);

    bson_buffer_init(&bb);
    bson_append_string(&bb, cast(char*)"user", user);
    bson_from_buffer(&user_obj, &bb);

    bson_buffer_init(&bb);
    bson_append_start_object(&bb, cast(char*)"$set");
    bson_append_string(&bb, cast(char*)"pwd", cast(char*)hex_digest);
    bson_append_finish_object(&bb);
    bson_from_buffer(&pass_obj, &bb);


    res = mongo_update(conn, ns, &user_obj, &pass_obj, MONGO_UPDATE_UPSERT);

    free(ns);
    bson_destroy(&user_obj);
    bson_destroy(&pass_obj);

    return res;
}

bson_bool_t mongo_cmd_authenticate(mongo_connection* conn, const char* db, const char* user, const char* pass){
    bson_buffer bb;
    bson from_db, auth_cmd;
    char* nonce;
    bson_bool_t success = 0;

    mongo_md5_state_t st;
    mongo_md5_byte_t digest[16];
    char hex_digest[33];

    if( mongo_simple_int_command(conn, db, cast(char*)"getnonce", 1, &from_db) == MONGO_OK ) {
        bson_iterator it;
        bson_find(&it, &from_db, cast(char*)"nonce");
        nonce = bson_iterator_string(&it);
    }
    else {
        return MONGO_ERROR;
    }

    mongo_pass_digest(user, pass, hex_digest);

    mongo_md5_init(&st);
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)nonce, strlen(nonce));
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)user, strlen(user));
    mongo_md5_append(&st, cast(const mongo_md5_byte_t*)hex_digest, 32);
    mongo_md5_finish(&st, digest);
    digest2hex(digest, hex_digest);

    bson_buffer_init(&bb);
    bson_append_int(&bb, cast(char*)"authenticate", 1);
    bson_append_string(&bb, cast(char*)"user", user);
    bson_append_string(&bb, cast(char*)"nonce", nonce);
    bson_append_string(&bb, cast(char*)"key", cast(char*)hex_digest);
    bson_from_buffer(&auth_cmd, &bb);

    bson_destroy(&from_db);

    if( mongo_run_command(conn, db, &auth_cmd, &from_db) == MONGO_OK ) {
        bson_iterator it;
        if(bson_find(&it, &from_db, cast(char*)"ok"))
            success = bson_iterator_bool(&it);
    }

    bson_destroy(&from_db);
    bson_destroy(&auth_cmd);

    if( success ) 
        return MONGO_OK;
    else
        return MONGO_ERROR;
}


version(BigEndian)
{
        ushort htons(ushort x)
        {
                return x;
        }
 

        uint htonl(uint x)
        {
                return x;
        }
}
else version(LittleEndian)
{
//        import tango.core.BitManip;


        ushort htons(ushort x)
        {
                return cast(ushort) ((x >> 8) | (x << 8));
        }
                

        uint htonl(uint x)
        {
                return bswap(x);
        }
}
else
{
        static assert(0);
}
        

ushort ntohs(ushort x)
{
        return htons(x);
}
        

uint ntohl(uint x)
{
        return htonl(x);
}

