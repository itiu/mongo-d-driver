rm *.o
rm *.a
git log -1 --pretty=format:"module myversion; public final static char[] author=\"%an\"; public final static char[] hash=\"%h\";">myversion.d
dmd src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod
