// D import file generated from 'src/mongo.d'
import md5;
import bson;
private import std.c.stdlib;

private import std.c.string;

private import std.intrinsic;

private import std.stdio;

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



public const static byte MONGO_INVALID_BSON = 6;



public const static int MONGO_TAILABLE = 1 << 1;



public const static int MONGO_SLAVE_OK = 1 << 2;



public const static int MONGO_NO_CURSOR_TIMEOUT = 1 << 4;



public const static int MONGO_AWAIT_DATA = 1 << 5;



public const static int MONGO_EXHAUST = 1 << 6;



public const static int MONGO_PARTIAL = 1 << 7;



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
struct mongo_connection
{
    mongo_host_port* primary;
    mongo_replset* replset;
    socket_t sock;
    bson_bool_t connected;
    int err;
    char* errstr;
    int lasterrcode;
    char* lasterrstr;
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
struct mongo_cursor
{
    mongo_reply* mm;
    mongo_connection* conn;
    char* ns;
    bson current;
}
enum : int
{
mongo_op_msg = 1000,
mongo_op_update = 2001,
mongo_op_insert = 2002,
mongo_op_query = 2004,
mongo_op_get_more = 2005,
mongo_op_delete = 2006,
mongo_op_kill_cursors = 2007,
}
enum : int
{
mongo_conn_success = 0,
mongo_conn_bad_arg,
mongo_conn_no_socket,
mongo_conn_fail,
mongo_conn_not_master,
mongo_conn_bad_set_name,
mongo_conn_cannot_find_primary,
}
static const int MONGO_UPDATE_UPSERT = 1;

static const int MONGO_UPDATE_MULTI = 2;

static const int MONGO_INDEX_UNIQUE = 1;

static const int MONGO_INDEX_DROP_DUPS = 2;

enum 
{
IPPROTO_IP = 0,
IPPROTO_HOPOPTS = 0,
IPPROTO_ICMP = 1,
IPPROTO_IGMP = 2,
IPPROTO_IPIP = 4,
IPPROTO_TCP = 6,
IPPROTO_EGP = 8,
IPPROTO_PUP = 12,
IPPROTO_UDP = 17,
IPPROTO_IDP = 22,
IPPROTO_TP = 29,
IPPROTO_DCCP = 33,
IPPROTO_IPV6 = 41,
IPPROTO_ROUTING = 43,
IPPROTO_FRAGMENT = 44,
IPPROTO_RSVP = 46,
IPPROTO_GRE = 47,
IPPROTO_ESP = 50,
IPPROTO_AH = 51,
IPPROTO_ICMPV6 = 58,
IPPROTO_NONE = 59,
IPPROTO_DSTOPTS = 60,
IPPROTO_MTP = 92,
IPPROTO_ENCAP = 98,
IPPROTO_PIM = 103,
IPPROTO_COMP = 108,
IPPROTO_SCTP = 132,
IPPROTO_UDPLITE = 136,
IPPROTO_RAW = 255,
IPPROTO_MAX,
}
enum 
{
TCP_NODELAY = 1,
TCP_MAXSEG = 2,
TCP_CORK = 3,
TCP_KEEPIDLE = 4,
TCP_KEEPINTVL = 5,
TCP_KEEPCNT = 6,
TCP_SYNCNT = 7,
TCP_LINGER2 = 8,
TCP_DEFER_ACCEPT = 9,
TCP_WINDOW_CLAMP = 10,
TCP_INFO = 11,
TCP_QUICKACK = 12,
TCP_CONGESTION = 13,
TCP_MD5SIG = 14,
}
enum : int
{
AF_UNSPEC = 0,
AF_UNIX = 1,
AF_INET = 2,
AF_IPX = 4,
AF_APPLETALK = 5,
AF_INET6 = 10,
PF_UNSPEC = AF_UNSPEC,
PF_UNIX = AF_UNIX,
PF_INET = AF_INET,
PF_IPX = AF_IPX,
PF_APPLETALK = AF_APPLETALK,
PF_INET6 = AF_INET6,
}
extern (C) struct sockaddr_in
{
    int16_t sin_family = AF_INET;
    uint16_t sin_port;
    in_addr sin_addr;
    ubyte[8] sin_zero;
}

alias uint32_t in_addr_t;
extern (C) struct sockaddr
{
    ushort sa_family;
    ubyte[14] sa_data;
}

extern (C) union in_addr
{
    private union _S_un_t
{
    private struct _S_un_b_t
{
    uint8_t s_b1;
    uint8_t s_b2;
    uint8_t s_b3;
    uint8_t s_b4;
}

    _S_un_b_t S_un_b;
    private struct _S_un_w_t
{
    uint16_t s_w1;
    uint16_t s_w2;
}

    _S_un_w_t S_un_w;
    uint32_t S_addr;
}

    _S_un_t S_un;
    uint32_t s_addr;
    struct
{
uint8_t s_net;
uint8_t s_host;
union
{
uint16_t s_imp;
struct
{
uint8_t s_lh;
uint8_t s_impno;
}
}
}
}

alias int ssize_t;
version (linux)
{
    extern (C) ssize_t send(int __fd, void* __buf, size_t __n, int __flags);

    extern (C) ssize_t recv(int __fd, void* __buf, size_t __n, int __flags);

}
enum socket_type 
{
SOCK_STREAM = 1,
SOCK_DGRAM = 2,
SOCK_RAW = 3,
SOCK_RDM = 4,
SOCK_SEQPACKET = 5,
SOCK_DCCP = 6,
SOCK_PACKET = 10,
SOCK_CLOEXEC = std.conv.octal!(2000000),
SOCK_NONBLOCK = std.conv.octal!(4000),
}
version (Win32)
{
    pragma (lib, "ws2_32.lib");
    extern (Windows) 
{
    private typedef int socket_t = ~0;

    int send(int s, void* buf, int len, int flags);
    int recv(int s, void* buf, int len, int flags);
    int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
    uint inet_addr(const char* cp);
    int connect(socket_t s, sockaddr* name, socklen_t namelen);
    socket_t socket(int af, int type, int protocol);
}
    private typedef int socklen_t;

}
version (linux)
{
    private typedef int socket_t = ~0;

    extern (C) int socket(int __domain, int __type, int __protocol);

    private typedef int socklen_t;

    extern (C) in_addr_t inet_addr(const char* __cp);

    extern (C) int connect(socket_t __fd, sockaddr* __addr, socklen_t __len);

    extern (C) int setsockopt(int __fd, int __level, int __optname, void* __optval, socklen_t __optlen);

}
static const int zero = 0;

static const int one = 1;

static int looping_write(mongo_connection* conn, const void* buf, int len);

static int looping_read(mongo_connection* conn, void* buf, int len);

int mongo_message_send(mongo_connection* conn, mongo_message* mm);
char* mongo_data_append(char* start, const void* data, int len)
{
memcpy(start,data,len);
return start + len;
}
char* mongo_data_append32(char* start, const void* data)
{
bson_little_endian32(start,data);
return start + 4;
}
char* mongo_data_append64(char* start, const void* data)
{
bson_little_endian64(start,data);
return start + 8;
}
mongo_message* mongo_message_create(int len, int id, int responseTo, int op)
{
mongo_message* mm = cast(mongo_message*)bson_malloc(len);
if (!id)
id = rand();
mm.head.len = len;
mm.head.id = id;
mm.head.responseTo = responseTo;
mm.head.op = op;
return mm;
}
void mongo_close_socket(int sock);
version (_MONGO_USE_GETADDRINFO)
{
    static int mongo_socket_connect(mongo_connection* conn, const char* host, int port);

}
else
{
    static int mongo_socket_connect(mongo_connection* conn, const char* host, int port);

}
int mongo_connect(mongo_connection* conn, const char* host, int port)
{
conn.replset = null;
conn.primary = cast(mongo_host_port*)bson_malloc(mongo_host_port.sizeof);
strncpy(conn.primary.host.ptr,host,strlen(host) + 1);
conn.primary.port = port;
conn.primary.next = null;
conn.err = 0;
conn.errstr = null;
conn.lasterrcode = 0;
conn.lasterrstr = null;
return mongo_socket_connect(conn,host,port);
}
void mongo_replset_init_conn(mongo_connection* conn, const char* name)
{
conn.replset = cast(mongo_replset*)bson_malloc(mongo_replset.sizeof);
conn.replset.primary_connected = 0;
conn.replset.seeds = null;
conn.replset.hosts = null;
conn.replset.name = cast(char*)bson_malloc(strlen(name) + 1);
memcpy(conn.replset.name,name,strlen(name) + 1);
conn.primary = cast(mongo_host_port*)bson_malloc(mongo_host_port.sizeof);
conn.err = 0;
conn.errstr = null;
conn.lasterrcode = 0;
conn.lasterrstr = null;
}
static int mongo_replset_add_node(mongo_host_port** list, const char* host, int port);

static int mongo_replset_free_list(mongo_host_port** list);

int mongo_replset_add_seed(mongo_connection* conn, const char* host, int port)
{
return mongo_replset_add_node(&conn.replset.seeds,host,port);
}
static void mongo_parse_host(const char* host_string, mongo_host_port* host_port);

static int mongo_replset_check_seed(mongo_connection* conn);

static int mongo_replset_check_host(mongo_connection* conn);

int mongo_replset_connect(mongo_connection* conn);
int mongo_reconnect(mongo_connection* conn);
bson_bool_t mongo_disconnect(mongo_connection* conn);
bson_bool_t mongo_destroy(mongo_connection* conn);
static int mongo_bson_valid(mongo_connection* conn, const bson* bson, int write);

int mongo_insert_batch(mongo_connection* conn, const char* ns, bson** bsons, int count);
int mongo_insert(mongo_connection* conn, const char* ns, bson* bson);
int mongo_update(mongo_connection* conn, const char* ns, const bson* cond, const bson* op, int flags);
int mongo_remove(mongo_connection* conn, const char* ns, const bson* cond)
{
char* data;
mongo_message* mm = mongo_message_create(16 + 4 + strlen(ns) + 1 + 4 + bson_size(cond),0,0,mongo_op_delete);
data = &mm.data;
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,ns,strlen(ns) + 1);
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,cond.data,bson_size(cond));
return mongo_message_send(conn,mm);
}
int mongo_read_response(mongo_connection* conn, mongo_reply** mm);
mongo_cursor* mongo_find(mongo_connection* conn, const char* ns, bson* query, bson* fields, int nToReturn, int nToSkip, int options);
int mongo_find_one(mongo_connection* conn, const char* ns, bson* query, bson* fields, bson* _out);
int64_t mongo_count(mongo_connection* conn, const char* db, const char* ns, bson* query);
int mongo_cursor_get_more(mongo_cursor* cursor);
int mongo_cursor_next(mongo_cursor* cursor);
int mongo_cursor_destroy(mongo_cursor* cursor);
int mongo_create_index(mongo_connection* conn, const char* ns, bson* key, int options, bson* _out);
bson_bool_t mongo_create_simple_index(mongo_connection* conn, const char* ns, const char* field, int options, bson* _out)
{
bson_buffer bb;
bson b;
bson_bool_t success;
bson_buffer_init(&bb);
bson_append_int(&bb,field,1);
bson_from_buffer(&b,&bb);
success = mongo_create_index(conn,ns,&b,options,_out);
bson_destroy(&b);
return success;
}
int mongo_run_command(mongo_connection* conn, const char* db, bson* command, bson* _out)
{
bson fields;
int sl = strlen(db);
char* ns = cast(char*)bson_malloc(sl + 5 + 1);
int res;
strcpy(ns,db);
strcpy(ns + sl,cast(char*)".$cmd");
res = mongo_find_one(conn,ns,command,bson_empty(&fields),_out);
free(ns);
return res;
}
int mongo_simple_int_command(mongo_connection* conn, const char* db, const char* cmdstr, int arg, bson* realout);
int mongo_simple_str_command(mongo_connection* conn, const char* db, const char* cmdstr, const char* arg, bson* realout);
int mongo_cmd_drop_db(mongo_connection* conn, const char* db)
{
return mongo_simple_int_command(conn,db,cast(char*)"dropDatabase",1,null);
}
int mongo_cmd_drop_collection(mongo_connection* conn, const char* db, const char* collection, bson* _out)
{
return mongo_simple_str_command(conn,db,cast(char*)"drop",collection,_out);
}
void mongo_cmd_reset_error(mongo_connection* conn, const char* db)
{
mongo_simple_int_command(conn,db,cast(char*)"reseterror",1,null);
}
static int mongo_cmd_get_error_helper(mongo_connection* conn, const char* db, bson* realout, const char* cmdtype);

int mongo_cmd_get_prev_error(mongo_connection* conn, const char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,cast(char*)"getpreverror");
}
int mongo_cmd_get_last_error(mongo_connection* conn, const char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,cast(char*)"getlasterror");
}
bson_bool_t mongo_cmd_ismaster(mongo_connection* conn, bson* realout);
static void digest2hex(mongo_md5_byte_t[16] digest, char[33] hex_digest);

static void mongo_pass_digest(const char* user, const char* pass, char[33] hex_digest)
{
mongo_md5_state_t st;
mongo_md5_byte_t[16] digest;
mongo_md5_init(&st);
mongo_md5_append(&st,cast(const(mongo_md5_byte_t*))user,strlen(user));
mongo_md5_append(&st,cast(const(mongo_md5_byte_t*))":mongo:",7);
mongo_md5_append(&st,cast(const(mongo_md5_byte_t*))pass,strlen(pass));
mongo_md5_finish(&st,digest);
digest2hex(digest,hex_digest);
}

int mongo_cmd_add_user(mongo_connection* conn, const char* db, const char* user, const char* pass)
{
bson_buffer bb;
bson user_obj;
bson pass_obj;
char[33] hex_digest;
char* ns = cast(char*)bson_malloc(strlen(db) + strlen(cast(char*)".system.users") + 1);
int res;
strcpy(ns,db);
strcpy(ns + strlen(db),cast(char*)".system.users");
mongo_pass_digest(user,pass,hex_digest);
bson_buffer_init(&bb);
bson_append_string(&bb,cast(char*)"user",user);
bson_from_buffer(&user_obj,&bb);
bson_buffer_init(&bb);
bson_append_start_object(&bb,cast(char*)"$set");
bson_append_string(&bb,cast(char*)"pwd",cast(char*)hex_digest);
bson_append_finish_object(&bb);
bson_from_buffer(&pass_obj,&bb);
res = mongo_update(conn,ns,&user_obj,&pass_obj,MONGO_UPDATE_UPSERT);
free(ns);
bson_destroy(&user_obj);
bson_destroy(&pass_obj);
return res;
}
bson_bool_t mongo_cmd_authenticate(mongo_connection* conn, const char* db, const char* user, const char* pass);
version (BigEndian)
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
else
{
    version (LittleEndian)
{
    ushort htons(ushort x)
{
return cast(ushort)(x >> 8 | x << 8);
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
}
ushort ntohs(ushort x)
{
return htons(x);
}
uint ntohl(uint x)
{
return htonl(x);
}
