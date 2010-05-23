// D import file generated from 'src\mongo.d'
module mongo;
import md5;
import bson;
private
{
    import tango.stdc.stdlib;
}
private
{
    import tango.stdc.string;
}
private
{
    import tango.stdc.stdio;
}
private
{
    import tango.io.Stdout;
}
private
{
    import tango.core.BitManip;
}
version (Win32)
{
    pragma(lib, "ws2_32.lib");
    extern (Windows) 
{
    private
{
    typedef int socket_t = ~0;
}
    int send(int s, void* buf, int len, int flags);
    int recv(int s, void* buf, int len, int flags);
    int setsockopt(socket_t s, int level, int optname, void* optval, int optlen);
    uint inet_addr(char* cp);
    int connect(socket_t s, sockaddr* name, socklen_t namelen);
    socket_t socket(int af, int type, int protocol);
}
    private
{
    typedef int socklen_t;
}
}
version (linux)
{
    private
{
    typedef int socket_t = ~0;
}
    extern (C) 
{
    int socket(int __domain, int __type, int __protocol);
}
    private
{
    typedef int socklen_t;
}
    extern (C) 
{
    in_addr_t inet_addr(char* __cp);
}
    extern (C) 
{
    int connect(socket_t __fd, sockaddr* __addr, socklen_t __len);
}
    extern (C) 
{
    int setsockopt(int __fd, int __level, int __optname, void* __optval, socklen_t __optlen);
}
}
static
{
    int zero = 0;
}
static
{
    int one = 1;
}
enum mongo_exception_type 
{
MONGO_EXCEPT_NETWORK = 1,
MONGO_EXCEPT_FIND_ERR,
}
enum mongo_conn_return 
{
mongo_conn_success = 0,
mongo_conn_bad_arg,
mongo_conn_no_socket,
mongo_conn_fail,
mongo_conn_not_master,
}
struct mongo_connection_options
{
    char[255] host;
    int port;
}
alias int bson_bool_t;
alias byte int8_t;
alias ubyte uint8_t;
alias short int16_t;
alias ushort uint16_t;
alias int int32_t;
alias uint uint32_t;
alias long int64_t;
alias ulong uint64_t;
extern (C) 
{
    union in_addr
{
    private
{
    union _S_un_t
{
    private
{
    struct _S_un_b_t
{
    uint8_t s_b1;
    uint8_t s_b2;
    uint8_t s_b3;
    uint8_t s_b4;
}
}
    _S_un_b_t S_un_b;
    private
{
    struct _S_un_w_t
{
    uint16_t s_w1;
    uint16_t s_w2;
}
}
    _S_un_w_t S_un_w;
    uint32_t S_addr;
}
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
extern (C) 
{
    struct sockaddr_in
{
    int16_t sin_family = AF_INET;
    uint16_t sin_port;
    in_addr sin_addr;
    ubyte[8] sin_zero;
}
}
const _SIGSET_NWORDS = 1024 / (8 * (uint).sizeof);
extern (C) 
{
    struct __sigset_t
{
    uint[_SIGSET_NWORDS] __val;
}
}
version (WORDSIZE64)
{
    alias short[8] __jmp_buf;
}
else
{
    alias short[6] __jmp_buf;
}
struct __jmp_buf_tag
{
    __jmp_buf __jmpbuf;
    int __mask_was_saved;
    __sigset_t __saved_mask;
}
alias __jmp_buf_tag[1] jmp_buf;
extern (C) 
{
    void longjmp(__jmp_buf_tag[1] __env, int __val);
}
struct mongo_exception_context
{
    jmp_buf base_handler;
    jmp_buf* penv;
    int caught;
    mongo_exception_type type;
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
struct mongo_connection
{
    mongo_connection_options* left_opts;
    mongo_connection_options* right_opts;
    sockaddr_in sa;
    socklen_t addressSize;
    socket_t sock;
    bson_bool_t connected;
    mongo_exception_context exception;
}
struct mongo_reply_fields
{
    int flag;
    int cursorID;
    int cursorID1;
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
alias int ssize_t;
version (linux)
{
    extern (C) 
{
    ssize_t send(int __fd, void* __buf, size_t __n, int __flags);
}
    extern (C) 
{
    ssize_t recv(int __fd, void* __buf, size_t __n, int __flags);
}
}
extern (C) 
{
    int setjmp(jmp_buf __env);
}
alias uint32_t in_addr_t;
enum socket_type 
{
SOCK_STREAM = 1,
SOCK_DGRAM = 2,
SOCK_RAW = 3,
SOCK_RDM = 4,
SOCK_SEQPACKET = 5,
SOCK_DCCP = 6,
SOCK_PACKET = 10,
SOCK_CLOEXEC = 524288,
SOCK_NONBLOCK = 2048,
}
extern (C) 
{
    struct sockaddr
{
    ushort sa_family;
    ubyte[14] sa_data;
}
}
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
enum mongo_operations 
{
mongo_op_msg = 1000,
mongo_op_update = 2001,
mongo_op_insert = 2002,
mongo_op_query = 2004,
mongo_op_get_more = 2005,
mongo_op_delete = 2006,
mongo_op_kill_cursors = 2007,
}
static
{
    void looping_write(mongo_connection* conn, void* buf, int len);
}
static
{
    void looping_read(mongo_connection* conn, void* buf, int len);
}
void mongo_message_send(mongo_connection* conn, mongo_message* mm);
char* mongo_data_append(char* start, void* data, int len)
{
memcpy(start,data,len);
return start + len;
}
char* mongo_data_append32(char* start, void* data)
{
bson_little_endian32(start,data);
return start + 4;
}
char* mongo_data_append64(char* start, void* data)
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
static
{
    int mongo_connect_helper(mongo_connection* conn);
}
void MONGO_INIT_EXCEPTION(mongo_exception_context* exception_ptr);
mongo_conn_return mongo_connect(mongo_connection* conn, mongo_connection_options* options);
static
{
    void swap_repl_pair(mongo_connection* conn)
{
mongo_connection_options* tmp = conn.left_opts;
conn.left_opts = conn.right_opts;
conn.right_opts = tmp;
}
}
mongo_conn_return mongo_connect_pair(mongo_connection* conn, mongo_connection_options* left, mongo_connection_options* right);
mongo_conn_return mongo_reconnect(mongo_connection* conn);
void mongo_insert_batch(mongo_connection* conn, char* ns, bson** bsons, int count);
void mongo_insert(mongo_connection* conn, char* ns, bson* bson)
{
char* data;
mongo_message* mm = mongo_message_create(16 + 4 + strlen(ns) + 1 + bson_size(bson),0,0,mongo_operations.mongo_op_insert);
data = &mm.data;
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,ns,strlen(ns) + 1);
data = mongo_data_append(data,bson.data,bson_size(bson));
mongo_message_send(conn,mm);
}
void mongo_update(mongo_connection* conn, char* ns, bson* cond, bson* op, int flags)
{
char* data;
mongo_message* mm = mongo_message_create(16 + 4 + strlen(ns) + 1 + 4 + bson_size(cond) + bson_size(op),0,0,mongo_operations.mongo_op_update);
data = &mm.data;
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,ns,strlen(ns) + 1);
data = mongo_data_append32(data,&flags);
data = mongo_data_append(data,cond.data,bson_size(cond));
data = mongo_data_append(data,op.data,bson_size(op));
mongo_message_send(conn,mm);
}
void mongo_remove(mongo_connection* conn, char* ns, bson* cond)
{
char* data;
mongo_message* mm = mongo_message_create(16 + 4 + strlen(ns) + 1 + 4 + bson_size(cond),0,0,mongo_operations.mongo_op_delete);
data = &mm.data;
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,ns,strlen(ns) + 1);
data = mongo_data_append32(data,&zero);
data = mongo_data_append(data,cond.data,bson_size(cond));
mongo_message_send(conn,mm);
}
mongo_reply* mongo_read_response(mongo_connection* conn);
mongo_cursor* mongo_find(mongo_connection* conn, char* ns, bson* query, bson* fields, int nToReturn, int nToSkip, int options);
bson_bool_t mongo_find_one(mongo_connection* conn, char* ns, bson* query, bson* fields, bson* _out);
int64_t mongo_count(mongo_connection* conn, char* db, char* ns, bson* query);
bson_bool_t mongo_disconnect(mongo_connection* conn);
bson_bool_t mongo_destroy(mongo_connection* conn)
{
free(conn.left_opts);
free(conn.right_opts);
conn.left_opts = null;
conn.right_opts = null;
return mongo_disconnect(conn);
}
bson_bool_t mongo_cursor_get_more(mongo_cursor* cursor);
bson_bool_t mongo_cursor_next(mongo_cursor* cursor);
void mongo_cursor_destroy(mongo_cursor* cursor);
static const
{
    int MONGO_INDEX_UNIQUE = 1;
}
static const
{
    int MONGO_INDEX_DROP_DUPS = 2;
}
bson_bool_t mongo_create_index(mongo_connection* conn, char* ns, bson* key, int options, bson* _out);
bson_bool_t mongo_create_simple_index(mongo_connection* conn, char* ns, char* field, int options, bson* _out)
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
bson_bool_t mongo_run_command(mongo_connection* conn, char* db, bson* command, bson* _out)
{
bson fields;
int sl = strlen(db);
char* ns = cast(char*)bson_malloc(sl + 5 + 1);
bson_bool_t success;
strcpy(ns,db);
strcpy(ns + sl,".$cmd");
success = mongo_find_one(conn,ns,command,bson_empty(&fields),_out);
free(ns);
return success;
}
bson_bool_t mongo_simple_int_command(mongo_connection* conn, char* db, char* cmdstr, int arg, bson* realout);
bson_bool_t mongo_simple_str_command(mongo_connection* conn, char* db, char* cmdstr, char* arg, bson* realout);
bson_bool_t mongo_cmd_drop_db(mongo_connection* conn, char* db)
{
return mongo_simple_int_command(conn,db,"dropDatabase",1,null);
}
bson_bool_t mongo_cmd_drop_collection(mongo_connection* conn, char* db, char* collection, bson* _out)
{
return mongo_simple_str_command(conn,db,"drop",collection,_out);
}
void mongo_cmd_reset_error(mongo_connection* conn, char* db)
{
mongo_simple_int_command(conn,db,"reseterror",1,null);
}
static
{
    bson_bool_t mongo_cmd_get_error_helper(mongo_connection* conn, char* db, bson* realout, char* cmdtype);
}
bson_bool_t mongo_cmd_get_prev_error(mongo_connection* conn, char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,"getpreverror");
}
bson_bool_t mongo_cmd_get_last_error(mongo_connection* conn, char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,"getlasterror");
}
bson_bool_t mongo_cmd_ismaster(mongo_connection* conn, bson* realout);
static
{
    void digest2hex(mongo_md5_byte_t[16] digest, char[33] hex_digest);
}
static
{
    void mongo_pass_digest(char* user, char* pass, char[33] hex_digest)
{
mongo_md5_state_t st;
mongo_md5_byte_t[16] digest;
mongo_md5_init(&st);
mongo_md5_append(&st,cast(mongo_md5_byte_t*)user,strlen(user));
mongo_md5_append(&st,cast(mongo_md5_byte_t*)":mongo:",7);
mongo_md5_append(&st,cast(mongo_md5_byte_t*)pass,strlen(pass));
mongo_md5_finish(&st,digest);
digest2hex(digest,hex_digest);
}
}
static const
{
    int MONGO_UPDATE_UPSERT = 1;
}
static const
{
    int MONGO_UPDATE_MULTI = 2;
}
void mongo_cmd_add_user(mongo_connection* conn, char* db, char* user, char* pass);
private
{
    void MONGO_THROW_GENERIC(mongo_connection* conn, mongo_exception_type type_in);
}
bson_bool_t mongo_cmd_authenticate(mongo_connection* conn, char* db, char* user, char* pass);
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
    import tango.core.BitManip;
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
