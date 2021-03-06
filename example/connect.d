/*
* make: dmd -version=D2 -Iexport libmongod-D2.a example/connect.d
*
* -Iexport : path to the folder containing the files: 
*	bson.di, bson_h.di, md5.di, mongo.di, mongo_h.di, myversion.di, net.di, numbers.di
*/

module example;

import std.stdio;

private import mongod.mongo_h;
private import mongod.mongo;
private import mongod.bson_h;
private import mongod.bson;

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

