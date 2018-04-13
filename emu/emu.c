#include <stdio.h>

typedef unsigned short word;
typedef unsigned char byte;

static word mem[0x10000] = {0};
static word reg[7] = {0};
#define pc (reg[5])
#define sp (reg[6])
static char truth = 0;

static void tick(void);

int main(int argc, char **argv)
{
        FILE *infile = argc >= 1 ? fopen(argv[1], "r") : stdin;
        if (!infile) {
                puts("Could not open file.");
                return 1;
        }
        fread(mem, sizeof(word), 0xffff, infile);
        while (mem[0xffff] == 0) {
                tick();
        }
}

/* Decode address mode nibble into actual value */
static word *get_arg(byte mode)
{
        byte reg_off = mode & 7;
        word *ptr = reg_off == 7 ? mem + pc++ : reg + reg_off;
        return mode & 8 ? mem + *ptr : ptr;
}

/* Used for memory-mapped writes */
static void write(word *dest, word value)
{
        switch (dest - mem) {
        case 0xff00: putchar(value); break;
        case 0xff01: printf("%04x ", value); break;
        case 0xff02: printf("%05d ", value); break;
        default: *dest = value; break;
        }
}

void tick()
{
        word code  = mem[pc++];
//        printf("truth %04x sp %04x pc %04x code %04x\n", truth, sp, pc, code);
        byte op    = 0xf & code >> 12;
        word *arg0 = get_arg(0xf & code >> 4);
        word *arg1 = get_arg(0xf & code);

        byte alt  = (0x0800 & code) != 0;
        byte cond = (0x0400 & code) != 0;

        if (cond && !truth) {
                return;
        }
        switch (op) {
        case 0x0: write(arg0, *arg1); break;
        case 0x1: write(arg0, *arg0 + (alt ? -*arg1 : *arg1)); break;
        case 0x2: write(arg0, *arg0 * *arg1 / (alt ? 0x10000 : 1)); break;
        case 0x3: write(arg0, *arg0 * (alt ? 0x10000 : 1) / *arg1); break;
        case 0x4: {
                short tmp = (short)*arg0 % (short)*arg1;
                write(arg0, tmp + ((alt && *arg0 < 0) ? *arg1 : 0));
                break;
        }
        case 0x5: write(arg0, *arg0 >> (0xf & *arg1)); break;
        case 0x6: write(arg0, *arg0 << (0xf & *arg1)); break;
        case 0x7: write(arg0, *arg0 | *arg1); break;
        case 0x8: write(arg0, *arg0 & *arg1); break;
        case 0x9: write(arg0, *arg0 ^ *arg1); break;
        case 0xA: truth = alt != (*arg0 == *arg1); break;
        case 0xB: truth = alt != ((word)*arg0 > (word)*arg1); break;
        case 0xC: truth = alt != (*arg0 > *arg1); break;
        case 0xD: write(mem + sp++, *arg0); break;
        case 0xE: write(arg0, mem[--sp]); break;
        case 0xF: {
                write(mem + sp++, pc);
                write(&pc, *arg0);
                break;
        }
        }
}
