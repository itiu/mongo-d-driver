module md5;

/*
 Copyright (C) 1999, 2000, 2002 Aladdin Enterprises.  All rights reserved.

 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.

 L. Peter Deutsch
 ghost@aladdin.com

 */
/* $Id: md5.c,v 1.6 2002/04/13 19:20:28 lpd Exp $ */
/*
 Independent implementation of MD5 (RFC 1321).

 This code implements the MD5 Algorithm defined in RFC 1321, whose
 text is available at
 http://www.ietf.org/rfc/rfc1321.txt
 The code is derived from the text of the RFC, including the test suite
 (section A.5) but excluding the rest of Appendix A.  It does not include
 any code or documentation that is identified in the RFC as being
 copyrighted.

 The original and principal author of md5.c is L. Peter Deutsch
 <ghost@aladdin.com>.  Other authors are noted in the change history
 that follows (in reverse chronological order):

 2002-04-13 lpd Clarified derivation from RFC 1321; now handles byte order
 either statically or dynamically; added missing #include <string.h>
 in library.
 2002-03-11 lpd Corrected argument list for main(), and added int return
 type, in test program and T value program.
 2002-02-21 lpd Added missing #include <stdio.h> in test program.
 2000-07-03 lpd Patched to eliminate warnings about "constant is
 unsigned in ANSI C, signed in traditional"; made test program
 self-checking.
 1999-11-04 lpd Edited comments slightly for automatic TOC extraction.
 1999-10-18 lpd Fixed typo in header comment (ansi2knr rather than md5).
 1999-05-03 lpd Original version.
 */

//#include "md5.h"
//#include <string.h>
// version !
// BYTE_ORDER_big_endian 
// BYTE_ORDER_little_endian
// BYTE_ORDER_unknown

//private import tango.stdc.string;
//private import tango.core.BitManip;
private import std.c.stdlib;
private import std.c.string;
private import std.intrinsic;

private typedef uint mongo_md5_word_t; /* 32-bit byte */
private typedef ubyte mongo_md5_byte_t; /* 8-bit byte */

/* Define the state of the MD5 Algorithm. */
struct mongo_md5_state_t
{
	mongo_md5_word_t count[2]; /* message length in bits, lsw first */
	mongo_md5_word_t abcd[4]; /* digest buffer */
	mongo_md5_byte_t buf[64]; /* accumulate block */
};

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
	S44 = 21
};


/**
 * Swaps bytes in a 4 byte uint end-to-end, i.e. byte 0 becomes
 * byte 3, byte 1 becomes byte 2, byte 2 becomes byte 1, byte 3
 * becomes byte 0.
 */
/*
private uint bswap(uint v)
{
	uint res;
	byte* in_res = cast(byte*) &res;
	byte* in_v = cast(byte*) &v;
	*(in_res + 0) = *(in_v + 3);
	*(in_res + 1) = *(in_v + 2);
	*(in_res + 2) = *(in_v + 1);
	*(in_res + 3) = *(in_v + 0);
	return res;
}
*/

final static private void swap32(void* dst, uint bytes)
{
	assert((bytes & 0x03) is 0);

	auto p = cast(uint*) dst;
	while(bytes)
	{
		*p = bswap(*p);
		++p;
		bytes -= int.sizeof;
	}
}


static protected final void littleEndian32(ubyte* input, uint* output)
{
	output = cast(uint*) input;

	version(BigEndian)
		swap32(output.ptr, output.length * uint.sizeof);
}


private void mongo_md5_process(mongo_md5_state_t* pms, mongo_md5_byte_t* data)
{
	uint a, b, c, d;
	uint[16] x;

	littleEndian32(cast (ubyte*) data, x.ptr);

	a = pms.abcd[0];
	b = pms.abcd[1];
	c = pms.abcd[2];
	d = pms.abcd[3];

	/* Round 1 */
	ff(a, b, c, d, x[0], S11, 0xd76aa478); /* 1 */
	ff(d, a, b, c, x[1], S12, 0xe8c7b756); /* 2 */
	ff(c, d, a, b, x[2], S13, 0x242070db); /* 3 */
	ff(b, c, d, a, x[3], S14, 0xc1bdceee); /* 4 */
	ff(a, b, c, d, x[4], S11, 0xf57c0faf); /* 5 */
	ff(d, a, b, c, x[5], S12, 0x4787c62a); /* 6 */
	ff(c, d, a, b, x[6], S13, 0xa8304613); /* 7 */
	ff(b, c, d, a, x[7], S14, 0xfd469501); /* 8 */
	ff(a, b, c, d, x[8], S11, 0x698098d8); /* 9 */
	ff(d, a, b, c, x[9], S12, 0x8b44f7af); /* 10 */
	ff(c, d, a, b, x[10], S13, 0xffff5bb1); /* 11 */
	ff(b, c, d, a, x[11], S14, 0x895cd7be); /* 12 */
	ff(a, b, c, d, x[12], S11, 0x6b901122); /* 13 */
	ff(d, a, b, c, x[13], S12, 0xfd987193); /* 14 */
	ff(c, d, a, b, x[14], S13, 0xa679438e); /* 15 */
	ff(b, c, d, a, x[15], S14, 0x49b40821); /* 16 */

	/* Round 2 */
	gg(a, b, c, d, x[1], S21, 0xf61e2562); /* 17 */
	gg(d, a, b, c, x[6], S22, 0xc040b340); /* 18 */
	gg(c, d, a, b, x[11], S23, 0x265e5a51); /* 19 */
	gg(b, c, d, a, x[0], S24, 0xe9b6c7aa); /* 20 */
	gg(a, b, c, d, x[5], S21, 0xd62f105d); /* 21 */
	gg(d, a, b, c, x[10], S22, 0x2441453); /* 22 */
	gg(c, d, a, b, x[15], S23, 0xd8a1e681); /* 23 */
	gg(b, c, d, a, x[4], S24, 0xe7d3fbc8); /* 24 */
	gg(a, b, c, d, x[9], S21, 0x21e1cde6); /* 25 */
	gg(d, a, b, c, x[14], S22, 0xc33707d6); /* 26 */
	gg(c, d, a, b, x[3], S23, 0xf4d50d87); /* 27 */
	gg(b, c, d, a, x[8], S24, 0x455a14ed); /* 28 */
	gg(a, b, c, d, x[13], S21, 0xa9e3e905); /* 29 */
	gg(d, a, b, c, x[2], S22, 0xfcefa3f8); /* 30 */
	gg(c, d, a, b, x[7], S23, 0x676f02d9); /* 31 */
	gg(b, c, d, a, x[12], S24, 0x8d2a4c8a); /* 32 */

	/* Round 3 */
	hh(a, b, c, d, x[5], S31, 0xfffa3942); /* 33 */
	hh(d, a, b, c, x[8], S32, 0x8771f681); /* 34 */
	hh(c, d, a, b, x[11], S33, 0x6d9d6122); /* 35 */
	hh(b, c, d, a, x[14], S34, 0xfde5380c); /* 36 */
	hh(a, b, c, d, x[1], S31, 0xa4beea44); /* 37 */
	hh(d, a, b, c, x[4], S32, 0x4bdecfa9); /* 38 */
	hh(c, d, a, b, x[7], S33, 0xf6bb4b60); /* 39 */
	hh(b, c, d, a, x[10], S34, 0xbebfbc70); /* 40 */
	hh(a, b, c, d, x[13], S31, 0x289b7ec6); /* 41 */
	hh(d, a, b, c, x[0], S32, 0xeaa127fa); /* 42 */
	hh(c, d, a, b, x[3], S33, 0xd4ef3085); /* 43 */
	hh(b, c, d, a, x[6], S34, 0x4881d05); /* 44 */
	hh(a, b, c, d, x[9], S31, 0xd9d4d039); /* 45 */
	hh(d, a, b, c, x[12], S32, 0xe6db99e5); /* 46 */
	hh(c, d, a, b, x[15], S33, 0x1fa27cf8); /* 47 */
	hh(b, c, d, a, x[2], S34, 0xc4ac5665); /* 48 */

	/* Round 4 *//* Md5 not md4 */
	ii(a, b, c, d, x[0], S41, 0xf4292244); /* 49 */
	ii(d, a, b, c, x[7], S42, 0x432aff97); /* 50 */
	ii(c, d, a, b, x[14], S43, 0xab9423a7); /* 51 */
	ii(b, c, d, a, x[5], S44, 0xfc93a039); /* 52 */
	ii(a, b, c, d, x[12], S41, 0x655b59c3); /* 53 */
	ii(d, a, b, c, x[3], S42, 0x8f0ccc92); /* 54 */
	ii(c, d, a, b, x[10], S43, 0xffeff47d); /* 55 */
	ii(b, c, d, a, x[1], S44, 0x85845dd1); /* 56 */
	ii(a, b, c, d, x[8], S41, 0x6fa87e4f); /* 57 */
	ii(d, a, b, c, x[15], S42, 0xfe2ce6e0); /* 58 */
	ii(c, d, a, b, x[6], S43, 0xa3014314); /* 59 */
	ii(b, c, d, a, x[13], S44, 0x4e0811a1); /* 60 */
	ii(a, b, c, d, x[4], S41, 0xf7537e82); /* 61 */
	ii(d, a, b, c, x[11], S42, 0xbd3af235); /* 62 */
	ii(c, d, a, b, x[2], S43, 0x2ad7d2bb); /* 63 */
	ii(b, c, d, a, x[9], S44, 0xeb86d391); /* 64 */

	pms.abcd[0] += a;
	pms.abcd[1] += b;
	pms.abcd[2] += c;
	pms.abcd[3] += d;
	x[] = 0;
}

static protected final uint rotateLeft(uint x, uint n)
{
	/+version (D_InlineAsm_X86)
	 version (DigitalMars)
	 {
	 asm {
	 naked;
	 mov ECX,EAX;
	 mov EAX,4[ESP];
	 rol EAX,CL;
	 ret 4;
	 }
	 }
	 else
	 return (x << n) | (x >> (32-n));
	 else +/
	return (x << n) | (x >> (32 - n));
}

protected static uint h(uint x, uint y, uint z)
{
	return x ^ y ^ z;
}

protected static uint f(uint x, uint y, uint z)
{
	return (x & y) | (~x & z);
}

/***********************************************************************

 ***********************************************************************/

private static uint g(uint x, uint y, uint z)
{
	return (x & z) | (y & ~z);
}

/***********************************************************************

 ***********************************************************************/

private static uint i(uint x, uint y, uint z)
{
	return y ^ (x | ~z);
}

/***********************************************************************

 ***********************************************************************/

private static void ff(inout uint a, uint b, uint c, uint d, uint x, uint s,
		uint ac)
{
	a += f(b, c, d) + x + ac;
	a = rotateLeft(a, s);
	a += b;
}

/***********************************************************************

 ***********************************************************************/

private static void gg(inout uint a, uint b, uint c, uint d, uint x, uint s,
		uint ac)
{
	a += g(b, c, d) + x + ac;
	a = rotateLeft(a, s);
	a += b;
}

/***********************************************************************

 ***********************************************************************/

private static void hh(inout uint a, uint b, uint c, uint d, uint x, uint s,
		uint ac)
{
	a += h(b, c, d) + x + ac;
	a = rotateLeft(a, s);
	a += b;
}

/***********************************************************************

 ***********************************************************************/

private static void ii(inout uint a, uint b, uint c, uint d, uint x, uint s,
		uint ac)
{
	a += i(b, c, d) + x + ac;
	a = rotateLeft(a, s);
	a += b;
}

void mongo_md5_init(mongo_md5_state_t* pms)
{
	pms.count[0] = pms.count[1] = 0;
	pms.abcd[0] = 0x67452301;
	pms.abcd[1] = T_MASK ^ 0x10325476;/*0xefcdab89*/
	pms.abcd[2] = T_MASK ^ 0x67452301;/*0x98badcfe*/
	pms.abcd[3] = 0x10325476;
}

void mongo_md5_append(mongo_md5_state_t* pms, mongo_md5_byte_t* data,
		int nbytes)
{
	mongo_md5_byte_t* p = data;
	int left = nbytes;
	int offset = (pms.count[0] >> 3) & 63;
	mongo_md5_word_t nbits = cast(mongo_md5_word_t) (nbytes << 3);

	if(nbytes <= 0)
		return;

	/* Update the message length. */
	pms.count[1] += nbytes >> 29;
	pms.count[0] += nbits;
	if(pms.count[0] < nbits)
		pms.count[1]++;

	/* Process an initial partial block. */
	if(offset)
	{
		int copy = (offset + nbytes > 64 ? 64 - offset : nbytes);

		memcpy(pms.buf.ptr + offset, p, copy);
		if(offset + copy < 64)
			return;
		p += copy;
		left -= copy;
		mongo_md5_process(pms, pms.buf.ptr);
	}

	/* Process full blocks. */
	for(; left >= 64; p += 64 , left -= 64)
		mongo_md5_process(pms, p);

	/* Process a final partial block. */
	if(left)
		memcpy(pms.buf.ptr, p, left);
}

void mongo_md5_finish(mongo_md5_state_t* pms, mongo_md5_byte_t digest[16])
{
	static mongo_md5_byte_t pad[64] = [0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
			0, 0, 0, 0, 0, 0, 0, 0];
	mongo_md5_byte_t data[8];
	int i;

	/* Save the length before padding. */
	for(i = 0; i < 8; ++i)
		data[i] = cast(mongo_md5_byte_t) (pms.count[i >> 2] >> ((i & 3) << 3));
	/* Pad to 56 bytes mod 64. */
	mongo_md5_append(pms, pad.ptr, ((55 - (pms.count[0] >> 3)) & 63) + 1);
	/* Append the length. */
	mongo_md5_append(pms, data.ptr, 8);
	for(i = 0; i < 16; ++i)
		digest[i] = cast(mongo_md5_byte_t) (pms.abcd[i >> 2] >> ((i & 3) << 3));
}
