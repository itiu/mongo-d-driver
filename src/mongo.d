module mongo;

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

version (D2)
{
    alias const char const_char;
    private import core.sys.posix.setjmp1;
}
version (D1)
{
    alias char const_char;
}
        

version (Win32)
{
   pragma(lib, "ws2_32.lib");

   extern  (Windows)
   {
	  private typedef int socket_t = ~0;
	   
      int send(int s, void* buf, int len, int flags);
      int recv(int s, void* buf, int len, int flags);
      int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
      uint inet_addr(char* cp);
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
    extern (C) in_addr_t inet_addr (char *__cp);
    extern (C) int connect (socket_t __fd, sockaddr * __addr, socklen_t __len);
    extern (C) int setsockopt (int __fd, int __level, int __optname, void *__optval, socklen_t __optlen);
}


static int zero = 0;
static int one = 1;

enum mongo_exception_type
{
	MONGO_EXCEPT_NETWORK = 1,
	MONGO_EXCEPT_FIND_ERR
};

enum mongo_conn_return
{
	mongo_conn_success = 0,
	mongo_conn_bad_arg,
	mongo_conn_no_socket,
	mongo_conn_fail,
	mongo_conn_not_master /* leaves conn connected to slave */
};

struct mongo_connection_options
{
	char host[255];
	int port;
};

alias int bson_bool_t;

alias byte int8_t;
alias ubyte uint8_t;

alias short int16_t;
alias ushort uint16_t;

alias int int32_t;
alias uint uint32_t;

alias long int64_t;
alias ulong uint64_t;

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

// C unsigned long int = uint	
	
version (D1)
{
// sigset.h
	const _SIGSET_NWORDS = 1024 / (8 * uint.sizeof);
	
extern(C)
	struct __sigset_t
	  {
	    uint __val[_SIGSET_NWORDS];
	  };
	
	
// include/bits/setjmp.h	
version (WORDSIZE64)
{
	// C long int = int
	alias short __jmp_buf[8];
}
else
{
	// C int = short 
	alias short __jmp_buf[6];
}
	
	struct __jmp_buf_tag
	  {
	    // NOTE: The machine-dependent definitions of `__sigsetjmp'
	    //   assume that a `jmp_buf' begins with a `__jmp_buf' and that
	    //   `__mask_was_saved' follows it.  Do not move these members
	    //   or add others before it.  
	    __jmp_buf __jmpbuf;		// Calling environment.  
	    int __mask_was_saved;	// Saved the signal mask?  
	    __sigset_t __saved_mask;// Saved signal mask.  
	  };

	
alias __jmp_buf_tag[1] jmp_buf;

extern (C) void longjmp (__jmp_buf_tag __env[1], int __val);

}
//extern (C) uint16_t htons (uint16_t __hostshort);


struct mongo_exception_context
{
	jmp_buf base_handler;
	jmp_buf* penv;
	int caught;
	mongo_exception_type type;
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

struct mongo_connection
{
	mongo_connection_options* left_opts; /* always current server */
	mongo_connection_options* right_opts; /* unused with single server */
	sockaddr_in sa;
	socklen_t addressSize;
	socket_t sock;
	bson_bool_t connected;
	mongo_exception_context exception;
};

struct mongo_reply_fields
{
	int flag; /* non-zero on failure */
	int cursorID; //@@@@
	int cursorID1; //@@@@
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
	mongo_reply* mm; /* message is owned by cursor */
	mongo_connection* conn; /* connection is *not* owned by cursor */
	char* ns; /* owned by cursor */
	bson current;
};

alias int ssize_t;

version (linux)
{
extern(C)
	ssize_t send(int __fd, void* __buf, size_t __n, int __flags);

extern (C) ssize_t recv (int __fd, void *__buf, size_t __n, int __flags);
}

extern (C) int setjmp (jmp_buf __env);

alias uint32_t in_addr_t;

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

  SOCK_CLOEXEC = 02000000,      /* Atomically set close-on-exec flag for the
                                   new descriptor(s).  */
  SOCK_NONBLOCK = 04000         /* Atomically mark descriptor(s) as
                                   non-blocking.  */
};

extern (C)
struct sockaddr
{
  ushort sa_family;
  ubyte sa_data[14];
};


/* Standard well-defined IP protocols.  */
enum
  {
    IPPROTO_IP = 0,	   /* Dummy protocol for TCP.  */
    IPPROTO_HOPOPTS = 0,   /* IPv6 Hop-by-Hop options.  */
    IPPROTO_ICMP = 1,	   /* Internet Control Message Protocol.  */
    IPPROTO_IGMP = 2,	   /* Internet Group Management Protocol. */
    IPPROTO_IPIP = 4,	   /* IPIP tunnels (older KA9Q tunnels use 94).  */
    IPPROTO_TCP = 6,	   /* Transmission Control Protocol.  */
    IPPROTO_EGP = 8,	   /* Exterior Gateway Protocol.  */
    IPPROTO_PUP = 12,	   /* PUP protocol.  */
    IPPROTO_UDP = 17,	   /* User Datagram Protocol.  */
    IPPROTO_IDP = 22,	   /* XNS IDP protocol.  */
    IPPROTO_TP = 29,	   /* SO Transport Protocol Class 4.  */
    IPPROTO_DCCP = 33,	   /* Datagram Congestion Control Protocol.  */
    IPPROTO_IPV6 = 41,     /* IPv6 header.  */
    IPPROTO_ROUTING = 43,  /* IPv6 routing header.  */
    IPPROTO_FRAGMENT = 44, /* IPv6 fragmentation header.  */
    IPPROTO_RSVP = 46,	   /* Reservation Protocol.  */
    IPPROTO_GRE = 47,	   /* General Routing Encapsulation.  */
    IPPROTO_ESP = 50,      /* encapsulating security payload.  */
    IPPROTO_AH = 51,       /* authentication header.  */
    IPPROTO_ICMPV6 = 58,   /* ICMPv6.  */
    IPPROTO_NONE = 59,     /* IPv6 no next header.  */
    IPPROTO_DSTOPTS = 60,  /* IPv6 destination options.  */
    IPPROTO_MTP = 92,	   /* Multicast Transport Protocol.  */
    IPPROTO_ENCAP = 98,	   /* Encapsulation Header.  */
    IPPROTO_PIM = 103,	   /* Protocol Independent Multicast.  */
    IPPROTO_COMP = 108,	   /* Compression Header Protocol.  */
    IPPROTO_SCTP = 132,	   /* Stream Control Transmission Protocol.  */
    IPPROTO_UDPLITE = 136, /* UDP-Lite protocol.  */
    IPPROTO_RAW = 255,	   /* Raw IP packets.  */
    IPPROTO_MAX
  };

enum
{
	TCP_NODELAY = 1,		/* Turn off Nagle's algorithm. */
	TCP_MAXSEG = 2,			/* Limit MSS */
	TCP_CORK = 3,			/* Never send partially complete segments */
	TCP_KEEPIDLE = 4,		/* Start keeplives after this period */
	TCP_KEEPINTVL = 5,		/* Interval between keepalives */
	TCP_KEEPCNT = 6,		/* Number of keepalives before death */
	TCP_SYNCNT = 7,			/* Number of SYN retransmits */
	TCP_LINGER2 = 8,		/* Life time of orphaned FIN-WAIT-2 state */
	TCP_DEFER_ACCEPT = 9,	/* Wake up listener only when data arrive */
	TCP_WINDOW_CLAMP = 10,	/* Bound advertised window */
	TCP_INFO = 11,			/* Information about this connection. */
	TCP_QUICKACK = 12,		/* Block/reenable quick acks */
	TCP_CONGESTION = 13,	/* Congestion control algorithm */
	TCP_MD5SIG = 14			/* TCP MD5 Signature (RFC2385) */
};

enum mongo_operations {
    mongo_op_msg = 1000,    /* generic msg command followed by a string */
    mongo_op_update = 2001, /* update object */
    mongo_op_insert = 2002,
    mongo_op_query = 2004,
    mongo_op_get_more = 2005,
    mongo_op_delete = 2006,
    mongo_op_kill_cursors = 2007
};






/* ----------------------------
 message stuff
 ------------------------------ */

static void looping_write(mongo_connection* conn, void* buf, int len)
{
	char* cbuf = cast(char*) buf;
	while(len > 0)
	{
		int sent = send(conn.sock, cbuf, len, 0);
		if(sent == -1)
			for(; ; longjmp(*conn.exception.penv, mongo_exception_type.MONGO_EXCEPT_NETWORK))
				conn.exception.type = mongo_exception_type.MONGO_EXCEPT_NETWORK;
		cbuf += sent;
		len -= sent;
	}
}

static void looping_read(mongo_connection* conn, void* buf, int len)
{
//Stdout.format("looping_read ###1 len={}", len).newline;
	char* cbuf = cast(char*)buf;
	while(len > 0)
	{
//Stdout.format("looping_read ###2").newline;
//	for (int q = 0; q < len; q++)
//	 Stdout.format("[{}]", *(cbuf+q)) ;
	 
		int sent = recv(conn.sock, cbuf, len, 0);

//Stdout.format("looping_read ###3").newline;
//	for (int q = 0; q < len; q++)
//	 Stdout.format("[{}]", *(cbuf+q)) ;
//Stdout.format("").newline;
	 
		if(sent == 0 || sent == -1)
		{
//Stdout.format("looping_read ###4 sent = {}", sent).newline;
			for(; ; longjmp(*conn.exception.penv, mongo_exception_type.MONGO_EXCEPT_NETWORK))
				conn.exception.type = mongo_exception_type.MONGO_EXCEPT_NETWORK;
		}
		cbuf += sent;
		len -= sent;
//Stdout.format("looping_read ###5 len = {}", len).newline;
	}
//Stdout.format("looping_read ###6").newline;
}

/* Always calls free(mm) */
void mongo_message_send(mongo_connection* conn, mongo_message* mm)
{
	mongo_header head; /* little endian */
	bson_little_endian32(&head.len, &mm.head.len);
	bson_little_endian32(&head.id, &mm.head.id);
	bson_little_endian32(&head.responseTo, &mm.head.responseTo);
	bson_little_endian32(&head.op, &mm.head.op);

	{
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
			do
			{
				looping_write(conn, &head, head.sizeof);
				looping_write(conn, &mm.data, mm.head.len - head.sizeof);
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		free(mm);

	}
	free(mm);
}

char* mongo_data_append(char* start, void* data, int len)
{
	memcpy(start, data, len);
	return start + len;
}

char* mongo_data_append32(char* start, void* data)
{
	bson_little_endian32(start, data);
	return start + 4;
}

char* mongo_data_append64(char* start, void* data)
{
	bson_little_endian64(start, data);
	return start + 8;
}

mongo_message* mongo_message_create(int len, int id, int responseTo, int op)
{
	mongo_message* mm = cast(mongo_message*) bson_malloc(len);

	if(!id)
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
static int mongo_connect_helper(mongo_connection* conn)
{
	/* setup */
	conn.sock = 0;
	conn.connected = 0;

	memset(conn.sa.sin_zero.ptr, 0, conn.sa.sin_zero.sizeof);
	conn.sa.sin_family = AF_INET;
	conn.sa.sin_port = htons(cast(ushort)conn.left_opts.port);
	conn.sa.sin_addr.s_addr = inet_addr(conn.left_opts.host.ptr);
	conn.addressSize = conn.sa.sizeof;

	/* connect */
	conn.sock = cast (socket_t)socket(AF_INET, socket_type.SOCK_STREAM, 0);
	if(conn.sock <= 0)
	{
		return mongo_conn_return.mongo_conn_no_socket;
	}

	if(connect(conn.sock, cast(sockaddr*) &conn.sa, conn.addressSize))
	{
		return mongo_conn_return.mongo_conn_fail;
	}

	/* nagle */
	setsockopt(conn.sock, IPPROTO_TCP, TCP_NODELAY, cast(char*) &one, one.sizeof);

	/* TODO signals */

	conn.connected = 1;
	return 0;
}

void MONGO_INIT_EXCEPTION (mongo_exception_context* exception_ptr)
{
    do{ 
        mongo_exception_type t; /* exception_ptr won't be available */
        exception_ptr.penv = &exception_ptr.base_handler;

	version (D2)
        int res_set_jmp = setjmp1(exception_ptr.base_handler);

	version (D1)
        int res_set_jmp = setjmp(exception_ptr.base_handler);

	if (res_set_jmp != 0)	
	{
        t = cast (mongo_exception_type)res_set_jmp;
            switch(t){ 
                case mongo_exception_type.MONGO_EXCEPT_NETWORK: bson_fatal_msg(0, cast(char*)"network error"); 
                case mongo_exception_type.MONGO_EXCEPT_FIND_ERR: bson_fatal_msg(0, cast(char*)"error in find"); 
                default: bson_fatal_msg(0, cast(char*)"mongodb:unknown exception"); 
            } 
            }
    }
    while(0)	
}

mongo_conn_return mongo_connect(mongo_connection* conn, mongo_connection_options* options)
{
	MONGO_INIT_EXCEPTION(&conn.exception);

	conn.left_opts = cast (mongo_connection_options*)bson_malloc(mongo_connection_options.sizeof);
	conn.right_opts = null;
//Stdout.format("###3").newline;

	if(options)
	{
		memcpy(conn.left_opts, options, mongo_connection_options.sizeof);
	}
	else
	{
		strcpy(conn.left_opts.host.ptr, cast(char*)"127.0.0.1".ptr);
		conn.left_opts.port = 27017;
	}

//Stdout.format("###4").newline;
	return cast (mongo_conn_return) mongo_connect_helper(conn);
}


static void swap_repl_pair(mongo_connection* conn)
{
	mongo_connection_options* tmp = conn.left_opts;
	conn.left_opts = conn.right_opts;
	conn.right_opts = tmp;
}

mongo_conn_return mongo_connect_pair(mongo_connection* conn, mongo_connection_options* left, mongo_connection_options* right)
{
	conn.connected = 0;
	MONGO_INIT_EXCEPTION(&conn.exception);

	conn.left_opts = null;
	conn.right_opts = null;

	if(!left || !right)
		return mongo_conn_return.mongo_conn_bad_arg;

	conn.left_opts = cast(mongo_connection_options*)bson_malloc(mongo_connection_options.sizeof);
	conn.right_opts = cast(mongo_connection_options*)bson_malloc(mongo_connection_options.sizeof);

	memcpy(conn.left_opts, left, mongo_connection_options.sizeof);
	memcpy(conn.right_opts, right, mongo_connection_options.sizeof);

	return mongo_reconnect(conn);
}

mongo_conn_return mongo_reconnect(mongo_connection* conn)
{
	mongo_conn_return ret;
	mongo_disconnect(conn);

	/* single server */
	if(conn.right_opts is null)
		return cast (mongo_conn_return)mongo_connect_helper(conn);

	/* repl pair */
	ret = cast(mongo_conn_return)mongo_connect_helper(conn);
	if(ret == mongo_conn_return.mongo_conn_success && mongo_cmd_ismaster(conn, null))
	{
		return mongo_conn_return.mongo_conn_success;
	}

	swap_repl_pair(conn);

	ret = cast(mongo_conn_return)mongo_connect_helper(conn);
	if(ret == mongo_conn_return.mongo_conn_success)
	{
		if(mongo_cmd_ismaster(conn, null))
			return mongo_conn_return.mongo_conn_success;
		else
			return mongo_conn_return.mongo_conn_not_master;
	}

	/* failed to connect to both servers */
	return ret;
}

void mongo_insert_batch(mongo_connection* conn, char* ns, bson** bsons, int count)
{
	int size = 16 + 4 + strlen(ns) + 1;
	int i;
	mongo_message* mm;
	char* data;

	for(i = 0; i < count; i++)
	{
		size += bson_size(bsons[i]);
	}

	mm = mongo_message_create(size, 0, 0, mongo_operations.mongo_op_insert);

	data = &mm.data;
	data = mongo_data_append32(data, &zero);
	data = mongo_data_append(data, ns, strlen(ns) + 1);

	for(i = 0; i < count; i++)
	{
		data = mongo_data_append(data, bsons[i].data, bson_size(bsons[i]));
	}

	mongo_message_send(conn, mm);
}

void mongo_insert(mongo_connection* conn, char* ns, bson* bson)
{
	char* data;
	mongo_message* mm = mongo_message_create(16 /* header */
	+ 4 /* ZERO */
	+ strlen(ns) + 1 + bson_size(bson), 0, 0, mongo_operations.mongo_op_insert);

	data = &mm.data;
	data = mongo_data_append32(data, &zero);
	data = mongo_data_append(data, ns, strlen(ns) + 1);
	data = mongo_data_append(data, bson.data, bson_size(bson));

	mongo_message_send(conn, mm);
}

void mongo_update(mongo_connection* conn, char* ns, bson* cond, bson* op, int flags)
{
	char* data;
	mongo_message* mm = mongo_message_create(16 /* header */
	+ 4 /* ZERO */
	+ strlen(ns) + 1 + 4 /* flags */
	+ bson_size(cond) + bson_size(op), 0, 0, mongo_operations.mongo_op_update);

	data = &mm.data;
	data = mongo_data_append32(data, &zero);
	data = mongo_data_append(data, ns, strlen(ns) + 1);
	data = mongo_data_append32(data, &flags);
	data = mongo_data_append(data, cond.data, bson_size(cond));
	data = mongo_data_append(data, op.data, bson_size(op));

	mongo_message_send(conn, mm);
}

void mongo_remove(mongo_connection* conn, char* ns, bson* cond)
{
	char* data;
	mongo_message* mm = mongo_message_create(16 /* header */
	+ 4 /* ZERO */
	+ strlen(ns) + 1 + 4 /* ZERO */
	+ bson_size(cond), 0, 0, mongo_operations.mongo_op_delete);

	data = &mm.data;
	data = mongo_data_append32(data, &zero);
	data = mongo_data_append(data, ns, strlen(ns) + 1);
	data = mongo_data_append32(data, &zero);
	data = mongo_data_append(data, cond.data, bson_size(cond));

	mongo_message_send(conn, mm);
}

mongo_reply* mongo_read_response(mongo_connection* conn)
{
//Stdout.format("mongo_read_response ###1").newline;
	mongo_header head; /* header from network */
	mongo_reply_fields fields; /* header from network */
	mongo_reply* _out; /* native endian */
	int len;
//Stdout.format("mongo_read_response ###2").newline;

	looping_read(conn, &head, head.sizeof);
	looping_read(conn, &fields, fields.sizeof);
//Stdout.format("mongo_read_response ###3").newline;

	bson_little_endian32(&len, &head.len);
	_out = cast(mongo_reply*) bson_malloc(len);
//Stdout.format("mongo_read_response ###4").newline;

	_out.head.len = len;
	bson_little_endian32(&_out.head.id, &head.id);
	bson_little_endian32(&_out.head.responseTo, &head.responseTo);
	bson_little_endian32(&_out.head.op, &head.op);
//Stdout.format("mongo_read_response ###5").newline;

	bson_little_endian32(&_out.fields.flag, &fields.flag);
	bson_little_endian64(&_out.fields.cursorID, &fields.cursorID);
	bson_little_endian32(&_out.fields.start, &fields.start);
	bson_little_endian32(&_out.fields.num, &fields.num);

	{
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
			do
			{
				looping_read(conn, &_out.objs, len - head.sizeof - fields.sizeof);
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		free(_out);
	}
//Stdout.format("mongo_read_response ###6").newline;

	return _out;
}

mongo_cursor* mongo_find(mongo_connection* conn, char* ns, bson* query, bson* fields, int nToReturn, int nToSkip, int options)
{
//Stdout.format("mongo_find ###3").newline;
	int sl;
	mongo_cursor* cursor;
	char* data;
	mongo_message* mm = mongo_message_create(16 + /* header */
	4 + /*  options */
	strlen(ns) + 1 + /* ns */
	4 + 4 + /* skip,return */
	bson_size(query) + bson_size(fields), 0, 0, mongo_operations.mongo_op_query);
//Stdout.format("mongo_find ###4").newline;

	data = &mm.data;
	data = mongo_data_append32(data, &options);
	data = mongo_data_append(data, ns, strlen(ns) + 1);
	data = mongo_data_append32(data, &nToSkip);
	data = mongo_data_append32(data, &nToReturn);
	data = mongo_data_append(data, query.data, bson_size(query));
	if(fields)
		data = mongo_data_append(data, fields.data, bson_size(fields));

	bson_fatal_msg((data == (cast(char*) mm) + mm.head.len), cast(char*)"query building fail!");

	mongo_message_send(conn, mm);
//Stdout.format("mongo_find ###5").newline;

	cursor = cast(mongo_cursor*) bson_malloc(mongo_cursor.sizeof);

	{
//Stdout.format("mongo_find ###5.1").newline;
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
//Stdout.format("mongo_find ###5.2").newline;
			do
			{
				cursor.mm = mongo_read_response(conn);
//Stdout.format("mongo_find ###5.3").newline;
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
//Stdout.format("mongo_find ###5.4").newline;
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		free(cursor);
	}
//Stdout.format("mongo_find ###6").newline;

	sl = strlen(ns) + 1;
	cursor.ns = cast (char*)bson_malloc(sl);
	if(!cursor.ns)
	{
		free(cursor.mm);
		free(cursor);
		return null;
	}
	memcpy(cast(void*) cursor.ns, ns, sl); /* cast needed to silence GCC warning */
	cursor.conn = conn;
	cursor.current.data = null;
//Stdout.format("mongo_find ###7").newline;
	return cursor;
}

bson_bool_t mongo_find_one(mongo_connection* conn, char* ns, bson* query, bson* fields, bson* _out)
{
	mongo_cursor* cursor = mongo_find(conn, ns, query, fields, 1, 0, 0);

	if(cursor && mongo_cursor_next(cursor))
	{
		bson_copy(_out, &cursor.current);
		mongo_cursor_destroy(cursor);
		return 1;
	}
	else
	{
		mongo_cursor_destroy(cursor);
		return 0;
	}
}

int64_t mongo_count(mongo_connection* conn, char* db, char* ns, bson* query)
{
	bson_buffer bb;
	bson cmd;
	bson _out;
	int64_t count = -1;

	bson_buffer_init(&bb);
	bson_append_string(&bb, cast(char[])"count", ns);
	if(query && bson_size(query) > 5)
		/* not empty */
		bson_append_bson(&bb, "query", query);
	bson_from_buffer(&cmd, &bb);

	{
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
			do
			{
				if(mongo_run_command(conn, db, &cmd, &_out))
				{
					bson_iterator it;
					if(bson_find(&it, &_out, cast(char*)"n"))
						count = bson_iterator_long(&it);
				}
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		bson_destroy(&cmd);
	}

	bson_destroy(&cmd);
	bson_destroy(&_out);
	return count;
}

bson_bool_t mongo_disconnect(mongo_connection* conn)
{
	if(!conn.connected)
		return 1;

	//#ifdef _WIN32
	version (windows)
	{
	closesocket(conn.sock);
	}
	else
	{
	//#else
//@@@@????	close(conn.sock);
	//#endif
	}

	conn.sock = 0;
	conn.connected = 0;

	return 0;
}

bson_bool_t mongo_destroy(mongo_connection* conn)
{
	free(conn.left_opts);
	free(conn.right_opts);
	conn.left_opts = null;
	conn.right_opts = null;

	return mongo_disconnect(conn);
}

bson_bool_t mongo_cursor_get_more(mongo_cursor* cursor)
{
	if(cursor.mm && cursor.mm.fields.cursorID)
	{
		mongo_connection* conn = cursor.conn;
		char* data;
		int sl = strlen(cursor.ns) + 1;
		mongo_message* mm = mongo_message_create(16 /*header*/
		+ 4 /*ZERO*/
		+ sl + 4 /*numToReturn*/
		+ 8 /*cursorID*/
		, 0, 0, mongo_operations.mongo_op_get_more);
		data = &mm.data;
		data = mongo_data_append32(data, &zero);
		data = mongo_data_append(data, cursor.ns, sl);
		data = mongo_data_append32(data, &zero);
		data = mongo_data_append64(data, &cursor.mm.fields.cursorID);
		mongo_message_send(conn, mm);

		free(cursor.mm);

		{
			jmp_buf* exception__prev; 
			jmp_buf exception__env;
			exception__prev = conn.exception.penv;
			conn.exception.penv = &exception__env;
			if(setjmp(exception__env) == 0)
			{
				do
				{
					cursor.mm = mongo_read_response(cursor.conn);
				} while(conn.exception.caught = 0 , conn.exception.caught);
			}
			else
			{
				conn.exception.caught = 1;
			}
			conn.exception.penv = exception__prev;
		}
		if(!conn.exception.caught)
		{
		}
		else
		{
			cursor.mm = null;
			mongo_cursor_destroy(cursor);
		}

		return cursor.mm && cursor.mm.fields.num;
	}
	else
	{
		return 0;
	}
}

bson_bool_t mongo_cursor_next(mongo_cursor* cursor)
{
	char* bson_addr;

	/* no data */
	if(!cursor.mm || cursor.mm.fields.num == 0)
		return 0;

	/* first */
	if(cursor.current.data is null)
	{
		bson_init(&cursor.current, &cursor.mm.objs, 0);
		return 1;
	}

	bson_addr = cursor.current.data + bson_size(&cursor.current);
	if(bson_addr >= (cast(char*) cursor.mm + cursor.mm.head.len))
	{
		if(!mongo_cursor_get_more(cursor))
			return 0;
		bson_init(&cursor.current, &cursor.mm.objs, 0);
	}
	else
	{
		bson_init(&cursor.current, bson_addr, 0);
	}

	return 1;
}

void mongo_cursor_destroy(mongo_cursor* cursor)
{
	if(!cursor)
		return;

	if(cursor.mm && cursor.mm.fields.cursorID)
	{
		mongo_connection* conn = cursor.conn;
		mongo_message* mm = mongo_message_create(16 /*header*/
		+ 4 /*ZERO*/
		+ 4 /*numCursors*/
		+ 8 /*cursorID*/
		, 0, 0, mongo_operations.mongo_op_kill_cursors);
		char* data = &mm.data;
		data = mongo_data_append32(data, &zero);
		data = mongo_data_append32(data, &one);
		data = mongo_data_append64(data, &cursor.mm.fields.cursorID);

		{
			jmp_buf* exception__prev; 
			jmp_buf exception__env;
			exception__prev = conn.exception.penv;
			conn.exception.penv = &exception__env;
			if(setjmp(exception__env) == 0)
			{
				do
				{
					mongo_message_send(conn, mm);
				} while(conn.exception.caught = 0 , conn.exception.caught);
			}
			else
			{
				conn.exception.caught = 1;
			}
			conn.exception.penv = exception__prev;
		}
		if(!conn.exception.caught)
		{
		}
		else
		{
			free(cursor.mm);
			free(cast(void*) cursor.ns);
			free(cursor);
		}
	}

	free(cursor.mm);
	free(cast(void*) cursor.ns);
	free(cursor);
}

static const int MONGO_INDEX_UNIQUE = 0x1;
static const int MONGO_INDEX_DROP_DUPS = 0x2;

bson_bool_t mongo_create_index(mongo_connection* conn, char* ns, bson* key, int options, bson* _out)
{
	bson_buffer bb;
	bson b;
	bson_iterator it;
	char name[255] = ['_'];
	int i = 1;
	char idxns[1024];

	bson_iterator_init(&it, key.data);
	while(i < 255 && bson_iterator_next(&it))
	{
		strncpy(name.ptr + i, bson_iterator_key(&it), 255 - i);
		i += strlen(bson_iterator_key(&it));
	}
	name[254] = '\0';

	bson_buffer_init(&bb);
	bson_append_bson(&bb, cast(char*)"key", key);
	bson_append_string(&bb, cast(char[])"ns", ns);
	bson_append_string(&bb, cast(char[])"name", name.ptr);
	if(options & MONGO_INDEX_UNIQUE)
		bson_append_bool(&bb, cast(char*)"unique", 1);
	if(options & MONGO_INDEX_DROP_DUPS)
		bson_append_bool(&bb, cast(char*)"dropDups", 1);

	bson_from_buffer(&b, &bb);

	strncpy(idxns.ptr, ns, 1024 - 16);
	strcpy(strchr(idxns.ptr, '.'), cast(char*)".system.indexes");
	mongo_insert(conn, idxns.ptr, &b);
	bson_destroy(&b);

	*strchr(idxns.ptr, '.') = '\0'; /* just db not ns */
	return !mongo_cmd_get_last_error(conn, idxns.ptr, _out);
}

bson_bool_t mongo_create_simple_index(mongo_connection* conn, char* ns, char* field, int options, bson* _out)
{
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

bson_bool_t mongo_run_command(mongo_connection* conn, char* db, bson* command, bson* _out)
{
	bson fields;
	int sl = strlen(db);
	char* ns = cast(char*)bson_malloc(sl + 5 + 1); /* ".$cmd" + nul */
	bson_bool_t success;

	strcpy(ns, db);
	strcpy(ns + sl, cast(char*)".$cmd");

	success = mongo_find_one(conn, ns, command, bson_empty(&fields), _out);
	free(ns);
	return success;
}

bson_bool_t mongo_simple_int_command(mongo_connection* conn, char* db, char* cmdstr, int arg, bson* realout)
{
	bson _out;
	bson cmd;
	bson_buffer bb;
	bson_bool_t success = 0;

	bson_buffer_init(&bb);
	bson_append_int(&bb, cmdstr, arg);
	bson_from_buffer(&cmd, &bb);

	if(mongo_run_command(conn, db, &cmd, &_out))
	{
		bson_iterator it;
		if(bson_find(&it, &_out, cast(char*)"ok"))
			success = bson_iterator_bool(&it);
	}

	bson_destroy(&cmd);

	if(realout)
		*realout = _out;
	else
		bson_destroy(&_out);

	return success;
}

bson_bool_t mongo_simple_str_command(mongo_connection* conn, char* db, string cmdstr, char* arg, bson* realout)
{
	bson _out;
	bson cmd;
	bson_buffer bb;
	bson_bool_t success = 0;

	bson_buffer_init(&bb);
	bson_append_string(&bb, cast(char[])cmdstr, arg);
	bson_from_buffer(&cmd, &bb);

	if(mongo_run_command(conn, db, &cmd, &_out))
	{
		bson_iterator it;
		if(bson_find(&it, &_out, cast(char*)"ok"))
			success = bson_iterator_bool(&it);
	}

	bson_destroy(&cmd);

	if(realout)
		*realout = _out;
	else
		bson_destroy(&_out);

	return success;
}

bson_bool_t mongo_cmd_drop_db(mongo_connection* conn, char* db)
{
	return mongo_simple_int_command(conn, db, cast(char*)"dropDatabase", 1, null);
}

bson_bool_t mongo_cmd_drop_collection(mongo_connection* conn, char* db, char* collection, bson* _out)
{
	return mongo_simple_str_command(conn, db, "drop", collection, _out);
}

void mongo_cmd_reset_error(mongo_connection* conn, char* db)
{
	mongo_simple_int_command(conn, db, cast(char*)"reseterror", 1, null);
}

static bson_bool_t mongo_cmd_get_error_helper(mongo_connection* conn, char* db, bson* realout, char* cmdtype)
{
	bson _out = {null, 0};
	bson_bool_t haserror = 1;

	if(mongo_simple_int_command(conn, db, cmdtype, 1, &_out))
	{
		bson_iterator it;
		haserror = (bson_find(&it, &_out, cast(char*)"err") != bson_type.bson_null);
	}

	if(realout)
		*realout = _out; /* transfer of ownership */
	else
		bson_destroy(&_out);

	return haserror;
}

bson_bool_t mongo_cmd_get_prev_error(mongo_connection* conn, char* db, bson* _out)
{
	return mongo_cmd_get_error_helper(conn, db, _out, cast(char*)"getpreverror");
}

bson_bool_t mongo_cmd_get_last_error(mongo_connection* conn, char* db, bson* _out)
{
	return mongo_cmd_get_error_helper(conn, db, _out, cast(char*)"getlasterror");
}

bson_bool_t mongo_cmd_ismaster(mongo_connection* conn, bson* realout)
{
	bson _out;
	_out.data = null;
	_out.owned = 0;
	
	bson_bool_t ismaster = 0;

	if(mongo_simple_int_command(conn, cast(char*)"admin", cast(char*)"ismaster", 1, &_out))
	{
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

static void digest2hex(mongo_md5_byte_t digest[16], char hex_digest[33])
{
	static const char hex[16] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
	int i;
	for(i = 0; i < 16; i++)
	{
		hex_digest[2 * i] = hex[(digest[i] & 0xf0) >> 4];
		hex_digest[2 * i + 1] = hex[digest[i] & 0x0f];
	}
	hex_digest[32] = '\0';
}

static void mongo_pass_digest(char* user, char* pass, char hex_digest[33])
{
	mongo_md5_state_t st;
	mongo_md5_byte_t digest[16];

	mongo_md5_init(&st);
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) user, strlen(user));
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) cast(char*)":mongo:", 7);
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) pass, strlen(pass));
	mongo_md5_finish(&st, digest);
	digest2hex(digest, hex_digest);
}

static const int MONGO_UPDATE_UPSERT = 0x1;
static const int MONGO_UPDATE_MULTI = 0x2;

void mongo_cmd_add_user(mongo_connection* conn, char* db, char* user, char* pass)
{
	bson_buffer bb;
	bson user_obj;
	bson pass_obj;
	char hex_digest[33];
	char* ns = cast(char*) malloc(strlen(db) + strlen(cast(char*)".system.users") + 1);

	strcpy(ns, db);
	strcpy(ns + strlen(db), cast(char*)".system.users");

	mongo_pass_digest(user, pass, hex_digest);

	bson_buffer_init(&bb);
	bson_append_string(&bb, cast(char[])"user", user);
	bson_from_buffer(&user_obj, &bb);

	bson_buffer_init(&bb);
	bson_append_start_object(&bb, "$set");
	bson_append_string(&bb, cast(char[])"pwd", hex_digest.ptr);
	bson_append_finish_object(&bb);
	bson_from_buffer(&pass_obj, &bb);

	{
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
			do
			{
				mongo_update(conn, ns, &user_obj, &pass_obj, MONGO_UPDATE_UPSERT);
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		free(ns);
		bson_destroy(&user_obj);
		bson_destroy(&pass_obj);
	}

	free(ns);
	bson_destroy(&user_obj);
	bson_destroy(&pass_obj);
}

private void MONGO_THROW_GENERIC(mongo_connection* conn, mongo_exception_type type_in) 
{
for (;; longjmp(*conn.exception.penv, type_in)) 
  conn.exception.type = type_in;
}

bson_bool_t mongo_cmd_authenticate(mongo_connection* conn, char* db, char* user, char* pass)
{
	bson_buffer bb;
	bson from_db, auth_cmd;
	char* nonce;
	bson_bool_t success = 0;

	mongo_md5_state_t st;
	mongo_md5_byte_t digest[16];
	char hex_digest[33];

	if(mongo_simple_int_command(conn, db, cast(char*)"getnonce", 1, &from_db))
	{
		bson_iterator it;
		bson_find(&it, &from_db, cast(char*)"nonce");
		nonce = bson_iterator_string(&it);
	}
	else
	{
		return 0;
	}

	mongo_pass_digest(user, pass, hex_digest);

	mongo_md5_init(&st);
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) nonce, strlen(nonce));
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) user, strlen(user));
	mongo_md5_append(&st, cast(mongo_md5_byte_t*) hex_digest, 32);
	mongo_md5_finish(&st, digest);
	digest2hex(digest, hex_digest);

	bson_buffer_init(&bb);
	bson_append_int(&bb, "authenticate", 1);
	bson_append_string(&bb, cast(char[])"user", user);
	bson_append_string(&bb, cast(char[])"nonce", nonce);
	bson_append_string(&bb, cast(char[])"key", hex_digest.ptr);
	bson_from_buffer(&auth_cmd, &bb);

	bson_destroy(&from_db);

	{
		jmp_buf* exception__prev; 
		jmp_buf exception__env;
		exception__prev = conn.exception.penv;
		conn.exception.penv = &exception__env;
		if(setjmp(exception__env) == 0)
		{
			do
			{
				if(mongo_run_command(conn, db, &auth_cmd, &from_db))
				{
					bson_iterator it;
					if(bson_find(&it, &from_db, "ok"))
						success = bson_iterator_bool(&it);
				}
			} while(conn.exception.caught = 0 , conn.exception.caught);
		}
		else
		{
			conn.exception.caught = 1;
		}
		conn.exception.penv = exception__prev;
	}
	if(!conn.exception.caught)
	{
	}
	else
	{
		bson_destroy(&auth_cmd);
		MONGO_THROW_GENERIC(conn, conn.exception.type);
	}

	bson_destroy(&from_db);
	bson_destroy(&auth_cmd);

	return success;
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
