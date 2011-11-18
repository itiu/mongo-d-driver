// D import file generated from 'src/mongod/md5.d'
module mongod.md5;
private import std.c.stdlib;

private import std.c.string;

private import std.intrinsic;

private typedef uint mongo_md5_word_t;

private typedef ubyte mongo_md5_byte_t;

struct mongo_md5_state_t
{
    mongo_md5_word_t[2] count;
    mongo_md5_word_t[4] abcd;
    mongo_md5_byte_t[64] buf;
}
const mongo_md5_word_t T_MASK = 0;

private enum 
{
S11 = 7,
S12 = 12,
S13 = 17,
S14 = 22,
S21 = 5,
S22 = 9,
S23 = 14,
S24 = 20,
S31 = 4,
S32 = 11,
S33 = 16,
S34 = 23,
S41 = 6,
S42 = 10,
S43 = 15,
S44 = 21,
}

final static private void swap32(void* dst, uint bytes);



static protected final void littleEndian32(ubyte* input, uint* output);



private void mongo_md5_process(mongo_md5_state_t* pms, mongo_md5_byte_t* data);

static protected final uint rotateLeft(uint x, uint n)
{
return x << n | x >> 32 - n;
}



protected static uint h(uint x, uint y, uint z)
{
return x ^ y ^ z;
}


protected static uint f(uint x, uint y, uint z)
{
return x & y | ~x & z;
}


private static uint g(uint x, uint y, uint z)
{
return x & z | y & ~z;
}


private static uint i(uint x, uint y, uint z)
{
return y ^ (x | ~z);
}


version (D1)
{
    private static void ff(uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += f(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D2)
{
    private static void ff(ref uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += f(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D1)
{
    private static void gg(uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += g(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D2)
{
    private static void gg(ref uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += g(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D1)
{
    private static void hh(uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += h(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D2)
{
    private static void hh(ref uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += h(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D1)
{
    private static void ii(uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += i(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
version (D2)
{
    private static void ii(ref uint a, uint b, uint c, uint d, uint x, uint s, uint ac)
{
a += i(b,c,d) + x + ac;
a = rotateLeft(a,s);
a += b;
}


}
void mongo_md5_init(mongo_md5_state_t* pms)
{
pms.count[0] = (pms.count[1] = 0);
pms.abcd[0] = 1732584193;
pms.abcd[1] = T_MASK ^ 271733878;
pms.abcd[2] = T_MASK ^ 1732584193;
pms.abcd[3] = 271733878;
}
void mongo_md5_append(mongo_md5_state_t* pms, const mongo_md5_byte_t* data, int nbytes);
void mongo_md5_finish(mongo_md5_state_t* pms, mongo_md5_byte_t[16] digest);
