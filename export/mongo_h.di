// D import file generated from 'src/mongo_h.d'
module mongo_h;
import bson_h;
private import std.socket;

public static string[] mongo_error_str = ["Connection success!","Could not create a socket.","An error occured while calling connect().","An error occured while calling getaddrinfo().","Warning: connected to a non-master node (read-only).","Given rs name doesn't match this replica set.","Can't find primary _in replica set. Connection closed.","An error occurred while reading or writing on socket.","The response is not the expected length.","The command returned with 'ok' value of 0.","The cursor has no more results.","The cursor has timed _out or is not recognized.","Tailable cursor still alive but no data.","BSON not valid for the specified op.","BSON object has not been finished."];


public static byte MONGO_MAJOR = 0;


public static byte MONGO_MINOR = 4;


public static byte MONGO_PATCH = 0;


public static byte MONGO_OK = 0;


public static byte MONGO_ERROR = -1;


public static int MONGO_DEFAULT_PORT = 27017;


enum mongo_error_t 
{
MONGO_CONN_SUCCESS = 0,
MONGO_CONN_NO_SOCKET,
MONGO_CONN_FAIL,
MONGO_CONN_ADDR_FAIL,
MONGO_CONN_NOT_MASTER,
MONGO_CONN_BAD_SET_NAME,
MONGO_CONN_NO_PRIMARY,
MONGO_IO_ERROR,
MONGO_READ_SIZE_ERROR,
MONGO_COMMAND_FAILED,
MONGO_CURSOR_EXHAUSTED,
MONGO_CURSOR_INVALID,
MONGO_CURSOR_PENDING,
MONGO_BSON_INVALID,
MONGO_BSON_NOT_FINISHED,
}
enum 
{
MONGO_CURSOR_MUST_FREE = 1,
MONGO_CURSOR_QUERY_SENT = 1 << 1,
}
enum 
{
MONGO_INDEX_UNIQUE = 1 << 0,
MONGO_INDEX_DROP_DUPS = 1 << 2,
MONGO_INDEX_BACKGROUND = 1 << 3,
MONGO_INDEX_SPARSE = 1 << 4,
}
enum 
{
MONGO_UPDATE_UPSERT = 1,
MONGO_UPDATE_MULTI = 2,
MONGO_UPDATE_BASIC = 4,
}
enum mongo_cursor_opts 
{
MONGO_TAILABLE = 1 << 1,
MONGO_SLAVE_OK = 1 << 2,
MONGO_NO_CURSOR_TIMEOUT = 1 << 4,
MONGO_AWAIT_DATA = 1 << 5,
MONGO_EXHAUST = 1 << 6,
MONGO_PARTIAL = 1 << 7,
}
enum 
{
MONGO_OP_MSG = 1000,
MONGO_OP_UPDATE = 2001,
MONGO_OP_INSERT = 2002,
MONGO_OP_QUERY = 2004,
MONGO_OP_GET_MORE = 2005,
MONGO_OP_DELETE = 2006,
MONGO_OP_KILL_CURSORS = 2007,
}
struct mongo_header
{
    int len;
    int id;
    int responseTo;
    int op;
}
struct mongo_message
{
    mongo_header head;
    char data;
}
struct mongo_reply_fields
{
    int flag;
    int64_t cursorID;
    int start;
    int num;
}
struct mongo_reply
{
    mongo_header head;
    mongo_reply_fields fields;
    char objs;
}
struct mongo_host_port
{
    char[255] host;
    int port;
    mongo_host_port* next;
}
struct mongo_replset
{
    mongo_host_port* seeds;
    mongo_host_port* hosts;
    char* name;
    bson_bool_t primary_connected;
}
struct mongo
{
    mongo_host_port* primary;
    mongo_replset* replset;
    Socket sock;
    int flags;
    int conn_timeout_ms;
    int op_timeout_ms;
    bson_bool_t connected;
    mongo_error_t err;
    char* errstr;
    int lasterrcode;
    char* lasterrstr;
}
struct mongo_cursor
{
    mongo_reply* reply;
    mongo* conn;
    char* ns;
    int flags;
    int seen;
    bson current;
    mongo_error_t err;
    bson* query;
    bson* fields;
    int options;
    int limit;
    int skip;
}
