// D import file generated from 'src/mongod/mongo.d'
module mongod.mongo;
private import std.c.stdlib;

private import std.c.string;

private import std.date;

private import std.c.stdio;

private import std.socket;

import mongod.bson_h;
import mongod.bson;
import mongod.mongo_h;
import mongod.md5;
static int ZERO = 0;

static int ONE = 1;

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
static int mongo_check_is_master(mongo* conn);

void mongo_init(mongo* conn)
{
conn.replset = null;
conn.err = cast(mongo_error_t)0;
conn.errstr = null;
conn.lasterrcode = 0;
conn.lasterrstr = null;
conn.conn_timeout_ms = 0;
conn.op_timeout_ms = 0;
}
void mongo_replset_init(mongo* conn, char* name)
{
mongo_init(conn);
conn.replset = cast(mongo_replset*)bson_malloc(mongo_replset.sizeof);
conn.replset.primary_connected = 0;
conn.replset.seeds = null;
conn.replset.hosts = null;
conn.replset.name = cast(char*)bson_malloc(strlen(name) + 1);
memcpy(conn.replset.name,name,strlen(name) + 1);
conn.primary = cast(mongo_host_port*)bson_malloc(mongo_host_port.sizeof);
}
static void mongo_replset_free_list(mongo_host_port** list);

static int mongo_replset_check_host(mongo* conn);

int mongo_replset_connect(mongo* conn);
int mongo_set_op_timeout(mongo* conn, int millis)
{
conn.op_timeout_ms = millis;
if (conn.sock && conn.connected)
mongo_set_socket_op_timeout(conn,millis);
return MONGO_OK;
}
int mongo_check_connection(mongo* conn);
void mongo_destroy(mongo* conn);
static int mongo_bson_valid(mongo* conn, bson* bson, int write);

static int mongo_cursor_bson_valid(mongo_cursor* cursor, bson* bson);

int mongo_insert_batch(mongo* conn, char* ns, bson** bsons, int count);
int mongo_insert(mongo* conn, char* ns, bson* bson);
int mongo_update(mongo* conn, char* ns, bson* cond, bson* op, int flags);
int mongo_remove(mongo* conn, char* ns, bson* cond);
static int mongo_cursor_op_query(mongo_cursor* cursor);

static int mongo_cursor_get_more(mongo_cursor* cursor);

mongo_cursor* mongo_find(mongo* conn, char* ns, bson* query, bson* fields, int limit, int skip, int options);
int mongo_find_one(mongo* conn, char* ns, bson* query, bson* fields, bson* _out);
void mongo_cursor_init(mongo_cursor* cursor, mongo* conn, char* ns)
{
cursor.conn = conn;
cursor.ns = cast(char*)bson_malloc(strlen(ns) + 1);
strncpy(cast(char*)cursor.ns,ns,strlen(ns) + 1);
cursor.current.data = null;
cursor.reply = null;
cursor.flags = 0;
cursor.seen = 0;
cursor.err = cast(mongo_error_t)0;
cursor.options = 0;
cursor.query = null;
cursor.fields = null;
cursor.skip = 0;
cursor.limit = 0;
}
void mongo_cursor_set_query(mongo_cursor* cursor, bson* query)
{
cursor.query = query;
}
void mongo_cursor_set_fields(mongo_cursor* cursor, bson* fields)
{
cursor.fields = fields;
}
void mongo_cursor_set_skip(mongo_cursor* cursor, int skip)
{
cursor.skip = skip;
}
void mongo_cursor_set_limit(mongo_cursor* cursor, int limit)
{
cursor.limit = limit;
}
void mongo_cursor_set_options(mongo_cursor* cursor, int options)
{
cursor.options = options;
}
char* mongo_cursor_data(mongo_cursor* cursor)
{
return cursor.current.data;
}
bson* mongo_cursor_bson(mongo_cursor* cursor)
{
return cast(bson*)&cursor.current;
}
int mongo_cursor_next(mongo_cursor* cursor);
int mongo_cursor_destroy(mongo_cursor* cursor);
int mongo_create_index(mongo* conn, char* ns, bson* key, int options, bson* _out);
bson_bool_t mongo_create_simple_index(mongo* conn, char* ns, char* field, int options, bson* _out)
{
bson b;
bson_bool_t success;
bson_init(&b);
bson_append_int(&b,field,1);
bson_finish(&b);
success = mongo_create_index(conn,ns,&b,options,_out);
bson_destroy(&b);
return success;
}
int64_t mongo_count(mongo* conn, char* db, char* ns, bson* query);
int mongo_run_command(mongo* conn, char* db, bson* command, bson* _out)
{
bson fields;
int sl = strlen(db);
char* ns = cast(char*)bson_malloc(sl + 5 + 1);
int res;
strcpy(ns,db);
strcpy(ns + sl,cast(char*)".$cmd");
res = mongo_find_one(conn,ns,command,bson_empty(&fields),_out);
bson_free(ns);
return res;
}
int mongo_simple_int_command(mongo* conn, char* db, char* cmdstr, int arg, bson* realout);
int mongo_simple_str_command(mongo* conn, char* db, char* cmdstr, char* arg, bson* realout);
int mongo_cmd_drop_db(mongo* conn, char* db)
{
return mongo_simple_int_command(conn,db,cast(char*)"dropDatabase",1,null);
}
int mongo_cmd_drop_collection(mongo* conn, char* db, char* collection, bson* _out)
{
return mongo_simple_str_command(conn,db,cast(char*)"drop",collection,_out);
}
void mongo_cmd_reset_error(mongo* conn, char* db)
{
mongo_simple_int_command(conn,db,cast(char*)"reseterror",1,null);
}
static int mongo_cmd_get_error_helper(mongo* conn, char* db, bson* realout, char* cmdtype);

int mongo_cmd_get_prev_error(mongo* conn, char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,cast(char*)"getpreverror");
}
int mongo_cmd_get_last_error(mongo* conn, char* db, bson* _out)
{
return mongo_cmd_get_error_helper(conn,db,_out,cast(char*)"getlasterror");
}
bson_bool_t mongo_cmd_ismaster(mongo* conn, bson* realout);
static void digest2hex(mongo_md5_byte_t[16] digest, char[33] hex_digest);

static void mongo_pass_digest(char* user, char* pass, char[33] hex_digest)
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

int mongo_cmd_add_user(mongo* conn, char* db, char* user, char* pass)
{
bson user_obj;
bson pass_obj;
char[33] hex_digest;
char* ns = cast(char*)bson_malloc(strlen(db) + strlen(cast(char*)".system.users") + 1);
int res;
strcpy(ns,db);
strcpy(ns + strlen(db),cast(char*)".system.users");
mongo_pass_digest(user,pass,hex_digest);
bson_init(&user_obj);
bson_append_string(&user_obj,cast(char*)"user",user);
bson_finish(&user_obj);
bson_init(&pass_obj);
bson_append_start_object(&pass_obj,cast(char*)"$set");
bson_append_string(&pass_obj,cast(char*)"pwd",hex_digest);
bson_append_finish_object(&pass_obj);
bson_finish(&pass_obj);
res = mongo_update(conn,ns,&user_obj,&pass_obj,MONGO_UPDATE_UPSERT);
bson_free(ns);
bson_destroy(&user_obj);
bson_destroy(&pass_obj);
return res;
}
bson_bool_t mongo_cmd_authenticate(mongo* conn, char* db, char* user, char* pass);
int mongo_read_response(mongo* conn, mongo_reply** reply, bool retry = false);
int mongo_message_send(mongo* conn, mongo_message* mm, bool retry = false);
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
int mongo_write_socket(mongo* conn, void* buf, int len);
int mongo_read_socket(mongo* conn, void* buf, int len);
int mongo_set_socket_op_timeout(mongo* conn, int millis)
{
return MONGO_OK;
}
int mongo_socket_connect(mongo* conn, string host, int port);
int mongo_connect(mongo* conn, string host, int port);
int mongo_reconnect(mongo* conn);
void mongo_disconnect(mongo* conn);
static void mongo_replset_add_node(mongo_host_port** list, string host, int port);

void mongo_parse_host(string host_string, mongo_host_port* host_port);
void mongo_replset_add_seed(mongo* conn, string host, int port)
{
mongo_replset_add_node(&conn.replset.seeds,host,port);
}
static void mongo_replset_check_seed(mongo* conn);

