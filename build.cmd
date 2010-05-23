del *.lib
del *.obj
del *.map
dmd src\mongo.d src\bson.d src\md5.d -Hdexport -release -lib -oflibmongod