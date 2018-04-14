#include <stdio.h>
#include <assert.h>

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
        assert(argv[1]);
        FILE *infile = fopen(argv[1], "r");
        assert(infile);
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

static word read(word *dest)
{
        switch (dest - mem) {
        case 0xff00: return getchar();
        default: return *dest;
        }
}

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
        word *ptr0 = get_arg(0xf & code >> 4);
        word *ptr1 = get_arg(0xf & code);
#define W(e) write(ptr0, e)
#define R0 read(ptr0)
#define R1 read(ptr1)

        byte alt  = (0x0800 & code) != 0;
        byte cond = (0x0400 & code) != 0;

        if (cond && !truth) {
                return;
        }
        switch (op) {
        case 0x0: W(R1); break;
        case 0x1: W(R0 + (alt ? -R1 : R1)); break;
        case 0x2: W(R0 * R1 / (alt ? 0x10000 : 1)); break;
        case 0x3: W(R0 * (alt ? 0x10000 : 1) / R1); break;
        case 0x4: {
                short r1 = R1, tmp = (short)R0 % r1;
                W(tmp + ((alt && tmp < 0) ? r1 : 0));
                break;
        }
        case 0x5: W(R0 >> (0xf & R1)); break;
        case 0x6: W(R0 << (0xf & R1)); break;
        case 0x7: W(R0 | R1); break;
        case 0x8: W(R0 & R1); break;
        case 0x9: W(R0 ^ R1); break;
        case 0xA: truth = alt != (R0 == R1); break;
        case 0xB: truth = alt != (R0 > R1); break;
        case 0xC: truth = alt != ((short)R0 > (short)R1); break;
        case 0xD: write(mem + sp++, R0); break;
        case 0xE: W(mem[--sp]); break;
        case 0xF: {
                write(mem + sp++, pc);
                write(&pc, R0);
                break;
        }
        }
}
