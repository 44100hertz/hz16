CC?=clang
CFLAGS:=-O2 -Wall $(CFLAGS)

all:
	$(CC) -o emulator emu/*.c $(CFLAGS)

.PHONY: all
