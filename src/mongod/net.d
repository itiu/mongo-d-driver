module mongod.net;

private import std.stdio;
private import std.c.string;
private import std.c.stdlib;
private import std.socket;
//private import std.intrinsic;

import mongod.mongo_h;
import mongod.bson_h;

int send(Socket sock, void* buf, size_t len, int flags)
{
	void[] bb = buf[0 .. len];
	int ll = cast(int)sock.send(bb);
	return ll;
}

int recv(Socket sock, void* buf, size_t len, int flags)
{
	void[] bb = buf[0 .. len];
	int ll = cast(int)sock.receive(bb);
	return ll;
}

void mongo_close_socket(Socket sock)
{
	sock.close();
}

int mongo_socket_connect(mongo* conn,  char* host, int port)
{
	conn.sock = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
	InternetAddress addr = new InternetAddress(cast(string) host[0 .. strlen(host)], cast(ushort) port);
	conn.sock.connect(addr);
	
	if (conn.sock.isAlive())
	{
	    conn.sock.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, true);
	    return MONGO_OK;
	}
	else
	{
    	    conn.sock = null;
            conn.err = mongo_error_t.MONGO_CONN_FAIL;
            return MONGO_ERROR;
                        	
	}
}

/* net.c */

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

/* Implementation for generic version of net.h */
//#include "net.h"
//#include <string.h>

int mongo_write_socket( mongo *conn,  void *buf, int len ) {
     char *cbuf = cast(char*)buf;
    while ( len ) {
        int sent = send( conn.sock, cbuf, len, 0 );
        if ( sent == -1 ) {
            conn.err = mongo_error_t.MONGO_IO_ERROR;
            return MONGO_ERROR;
        }
        cbuf += sent;
        len -= sent;
    }

    return MONGO_OK;
}

int mongo_read_socket( mongo *conn, void *buf, int len ) {
    char *cbuf = cast(char*)buf;
    while ( len ) {
        int sent = recv( conn.sock, cbuf, len, 0 );
        if ( sent == 0 || sent == -1 ) {
            conn.err = mongo_error_t.MONGO_IO_ERROR;
            return MONGO_ERROR;
        }
        cbuf += sent;
        len -= sent;
    }

    return MONGO_OK;
}

/* This is a no-op _in the generic implementation. */
int mongo_set_socket_op_timeout( mongo *conn, int millis ) {
    return MONGO_OK;
}

