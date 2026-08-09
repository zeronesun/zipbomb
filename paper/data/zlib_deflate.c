/* Compresses stdin to stdout using a raw DEFLATE stream. Adapted from
 * examples/zpipe.c in zlib 1.2.8. Public domain. */

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include "zlib.h"

/* Compress from file source to file dest, given an already initialized
 * z_stream. */
int def_sub(z_stream *strm, FILE *source, FILE *dest)
{
	int ret, flush;

	ret = Z_OK;
	flush = Z_NO_FLUSH;
	while (flush != Z_FINISH) {
		unsigned char in[BUFSIZ];

		strm->next_in = in;
		strm->avail_in = fread(in, 1, sizeof(in), source);
		if (ferror(source))
			return Z_ERRNO;
		if (feof(source))
			flush = Z_FINISH;

		do {
			unsigned char out[BUFSIZ];
			size_t have, n;

			strm->next_out = out;
			strm->avail_out = sizeof(out);
			ret = deflate(strm, flush);
			if (ret != Z_OK && ret != Z_STREAM_END)
				return ret;
			have = sizeof(out) - strm->avail_out;
			n = fwrite(out, 1, have, dest);
			if (n != have || ferror(dest))
				return Z_ERRNO;
		} while (strm->avail_out == 0);
		assert(strm->avail_in == 0);
	}
	assert(ret == Z_STREAM_END);
	return Z_OK;
}

/* Compress from file source to file dest. */
int def(FILE *source, FILE *dest)
{
	z_stream strm = {
		next_in: Z_NULL,
		zalloc: Z_NULL,
		zfree: Z_NULL,
		opaque: Z_NULL,
	};
	int ret;

	/* deflateInit2 parameters copied from:
	 *   https://github.com/madler/zlib/blob/v1.2.8/zlib.h#L1647-L1648
	 *   https://github.com/madler/zlib/blob/v1.2.8/deflate.c#L207-L208
	 * The only difference from deflateInit(&strm, Z_BEST_COMPRESSION) is
	 * that windowsBits is changed from MAX_WBITS to -MAX_WBITS to request a
	 * raw DEFLATE stream, and memLevel is increased from 8 to 9. */
	ret = deflateInit2(&strm, Z_BEST_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 9, Z_DEFAULT_STRATEGY);
	if (ret != Z_OK)
		return ret;

	ret = def_sub(&strm, source, dest);
	deflateEnd(&strm);
	return ret;
}

/* Report a zlib error to stderr. */
void err_msg(int ret)
{
	switch (ret) {
	case Z_ERRNO:
		fprintf(stderr, "error: %s\n", strerror(errno));
		break;
	case Z_STREAM_ERROR:
		fprintf(stderr, "error: invalid compression level\n");
		break;
	case Z_MEM_ERROR:
		fprintf(stderr, "error: out of memory\n");
		break;
	case Z_VERSION_ERROR:
		fprintf(stderr, "error: zlib version mismatch\n");
		break;
	default:
		fprintf(stderr, "error: other unknown error (code %d)\n", ret);
		break;
	}
}

int main(int argc, char *argv[])
{
	int ret;
	ret = def(stdin, stdout);
	if (ret != Z_OK)
		err_msg(ret);
	return ret;
}
