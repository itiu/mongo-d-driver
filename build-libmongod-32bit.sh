date
rm *.o
rm *.a
git log -1 --pretty=format:"module myversion; public static char[] author=cast(char[])\"%an\"; public static char[] date=cast(char[])\"%ad\"; public static char[] hash=cast(char[])\"%h\";">myversion.d
echo make libmongod
dmd -m32 -version=D2 myversion.d src/mongod/*.d -Hdexport/mongod -inline -d -release -lib -oflibmongod-D2
echo make example
dmd -m32 -version=D2 -Iexport libmongod-D2.a example/connect.d


