YCC ?= ycc
CAP = ulimit -S -v 3670016;

.PHONY: build run test clean win web webserve

build:
	mkdir -p build
	(cd tools/pack && $(CAP) $(YCC) build --gc=auto) </dev/null
	tools/pack/build/pack
	($(CAP) $(YCC) build --gc=auto --exec=off --obfuscate=full --obfuscate-no-anti-debug) </dev/null

run: build
	./build/judgement

test: build
	python3 tests/pty_test.py ./build/judgement

win:
	mkdir -p build
	(cd tools/pack && $(CAP) $(YCC) build --gc=auto) </dev/null
	tools/pack/build/pack
	($(CAP) $(YCC) build --target=win --gc=auto --exec=off --obfuscate=full --obfuscate-no-anti-debug) </dev/null

web:
	mkdir -p build
	(cd tools/pack && $(CAP) $(YCC) build --gc=auto) </dev/null
	tools/pack/build/pack
	($(CAP) $(YCC) build --target=web --gc=auto --exec=off) </dev/null

webserve:
	python3 -m http.server -d build/web/judgement 8000

clean:
	rm -rf build
