del *.obj
del *.map
dmd mongo.d bson.d md5.d -Hdexport -release -lib -oflibmongod