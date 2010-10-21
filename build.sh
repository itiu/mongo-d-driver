rm *.o
rm *.a
git log -1 --pretty=format:"module myversion; public static char[] author=\"%an\"; public static char[] hash=\"%h\";">myversion.d
#~/dmd2/linux/bin/dmd -version=D2 src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod
~/dmd/linux/bin/dmd -version=D1 src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod
