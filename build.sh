rm *.o
rm *.a
dmd src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod