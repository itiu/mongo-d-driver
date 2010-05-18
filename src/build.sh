rm *.o
rm *.a
dmd mongo.d bson.d md5.d -Hdexport -release -lib -oflibmongod