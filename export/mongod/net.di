// D import file generated from 'src/mongod/net.d'
module mongod.net;
private import std.stdio;

private import std.c.string;

private import std.c.stdlib;

private import std.socket;

private import std.intrinsic;

import mongod.mongo_h;
import mongod.bson_h;
int send(Socket sock, void* buf, size_t len, int flags)
{
void[] bb = buf[0..len];
int ll = sock.send(bb);
return ll;
}
int recv(Socket sock, void* buf, size_t len, int flags)
{
void[] bb = buf[0..len];
int ll = sock.receive(bb);
return ll;
}
void mongo_close_socket(Socket sock)
{
sock.close();
}
int mongo_socket_connect(mongo* conn, char* host, int port);
int mongo_write_socket(mongo* conn, void* buf, int len);
int mongo_read_socket(mongo* conn, void* buf, int len);
int mongo_set_socket_op_timeout(mongo* conn, int millis)
{
return MONGO_OK;
}
