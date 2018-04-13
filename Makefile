CC?=clang
CFLAGS:=-O2 -Wall $(CFLAGS)

%.bin: asm/%.asm
	cd assem/; luajit main.lua ../$^ ../$@

all:
	$(CC) -o bin/emu emu/*.c $(CFLAGS)

.PHONY: all
