date
rm *.o
rm *.a
git log -1 --pretty=format:"module myversion; public static char[] author=cast(char[])\"%an\"; public static char[] date=cast(char[])\"%ad\"; public static char[] hash=cast(char[])\"%h\";">myversion.d
~/dmd2-053/linux/bin32/dmd -version=D2 myversion.d src/numbers.d src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod-D2
#~/dmd1-064/linux/bin/dmd -version=D1 myversion.d src/setjmp1.d src/mongo.d src/bson.d src/md5.d -Hdexport -release -lib -oflibmongod-D1
