CC ?= gcc
CFLAGS ?= -O2

.PHONY: all
all:

versions.txt:
	( \
		true \
		&& printf "## zlib\n" && dpkg-query --show zlib1g-dev \
		&& printf "\n\n## zip\n" && zip -v \
		&& printf "\n\n## zopfli\n" && dpkg-query --show zopfli \
		&& printf "\n\n## bzip2\n" && bzip2 --version 2>&1 \
		&& printf "\n\n## 7z\n" && 7z i 2>&1 \
	) > "$@"

zlib_deflate: zlib_deflate.c
	$(CC) $(CFLAGS) -lz -o "$@" $^

compressed_size.csv.tmp: zlib_deflate zipbomb.py versions.txt
# tee to stdout to monitor progress
	./compressed_size.sh | tee "$@"
# it takes forever to run, so save partial results if interrupted
.PRECIOUS: compressed_size.csv.tmp

zipbomb.py:
	@echo "create a symlink zipbomb.py pointing to the zipbomb program"
	@echo "ln -sf [path to zipbomb] zipbomb.py"
	@false

compressed_size.csv: compressed_size.csv.tmp
	(echo "engine,uncompressed_size,compressed_size"; sort "$<" | uniq) > "$@"

.DELETE_ON_ERROR:
