module example;

import std.stdio;

private import mongo_h;
private import mongo;
private import bson_h;
private import bson;

void main(char[][] args)
{
	mongo conn;
        string collection = "test";      
        string host = "localhost";
        int port = 27017;
              
        char* col = cast(char*) collection;
        char* ns = cast(char*) (collection ~ ".simple");

	try
	{
    	    mongo_connect(&conn, host, port);
    	    writeln("connect to mongodb [", host, ":", port, "] sucessful");
    	    mongo_set_op_timeout(&conn, 1000);
	}
	catch (Exception ex)
	{
             writeln("failed to connect to mongodb, err=", ex.msg);
        }
}

