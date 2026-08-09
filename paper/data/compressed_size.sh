#!/bin/bash

set -e

PARALLELISM=8

repeated_bytes() {
	n="$1"
	dd if=/dev/zero bs="$n" count=1 2>/dev/null | tr '\0' 'a'
}
export -f repeated_bytes

trial_bulkdeflate() {
	uncompressed_size="$1"
	echo "bulk_deflate,$(./bulk_deflate "$uncompressed_size")"
}
export -f trial_bulkdeflate

trial_zlib() {
	uncompressed_size="$1"
	compressed_size="$(repeated_bytes "$uncompressed_size" | ./zlib_deflate | wc -c)"
	echo "zlib,$uncompressed_size,$compressed_size"
}
export -f trial_zlib

trial_infozip() {
	uncompressed_size="$1"
	tmp_filename="$(mktemp -u --suffix=.zip)"
	repeated_bytes "$uncompressed_size" | zip -X -9 -q "$tmp_filename" -
	zipinfo -v "$tmp_filename" | grep -q '^  compression method: *deflated$' || { echo "error: not deflated" 1>&2; exit 1; }
	compressed_size="$(zipinfo -v "$tmp_filename" | grep '^  compressed size:' | grep -E -o '[0-9]+')"
	echo "infozip,$uncompressed_size,$compressed_size"
	rm -f "$tmp_filename"
}
export -f trial_infozip

trial_zopfli() {
	uncompressed_size="$1"
	tmp_filename="$(mktemp -u --suffix=.zopfli-input)"
	repeated_bytes "$uncompressed_size" > "$tmp_filename"
	compressed_size="$(zopfli --deflate -c "$tmp_filename" | wc -c)"
	echo "zopfli,$uncompressed_size,$compressed_size"
	rm -f "$tmp_filename"
}
export -f trial_zopfli

trial_bzip2() {
	uncompressed_size="$1"
	compressed_size="$(repeated_bytes "$uncompressed_size" | bzip2 -c -9 | wc -c)"
	echo "bzip2,$uncompressed_size,$compressed_size"
}
export -f trial_bzip2

# Doesn't work well: for some reason -mfb=257 compresses better than -mfb=258, which points to a bug in the compressor.
# https://sourceforge.net/p/sevenzip/discussion/45797/thread/54b32538/#72d6/0d7d/132f
trial_7z() {
	uncompressed_size="$1"
	tmp_filename="$(mktemp -u --suffix=.7z)"
	repeated_bytes "$uncompressed_size" | 7z a -mm=Deflate -mx=9 -mfb=258 -si "$tmp_filename" > /dev/null
	7z l "$tmp_filename" | grep -q '^Method = Deflate$' || { echo "error: not deflated" 1>&2; exit 1; }
	compressed_size="$(7z l "$tmp_filename" | tail -n 1 | awk '{print $4}')"
	echo "7z,$uncompressed_size,$compressed_size"
	rm -f "$tmp_filename"
}
export -f trial_7z

run_parallel() {
	xargs -n 1 -P "$PARALLELISM" -I '{}' bash -c "$1"
}


seq 21725000 21755000 | run_parallel 'trial_bulkdeflate {}'
seq 21700000 21725000 | run_parallel 'trial_zlib {}'
seq 21700000 21725000 | run_parallel 'trial_infozip {}'
seq 21710000 21735000 | run_parallel 'trial_zopfli {}'
seq 21740000 21760000 | run_parallel 'trial_bzip2 {}'
# seq 14525000 14550000 | run_parallel 'trial_7z {}'
