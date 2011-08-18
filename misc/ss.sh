cat bson_i > ftmp
cat bson.c >> ftmp
cat encoding.c >> ftmp
./c_to_d.sh ftmp bson.d

cat bson_h_i > ftmp
cat bson.h >> ftmp
./c_to_d.sh ftmp bson_h.d

cat mongo_i > ftmp
cat mongo.c >> ftmp
./c_to_d.sh ftmp mongo.d

cat mongo_h_i > ftmp
cat mongo.h >> ftmp
./c_to_d.sh ftmp mongo_h.d

cat net_i > ftmp
cat net.c >> ftmp
./c_to_d.sh ftmp net.d
