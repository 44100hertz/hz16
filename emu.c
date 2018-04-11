#include <stdio.h>

typedef unsigned short word;
typedef unsigned char byte;

static word mem[0x10000] = {0};
static word reg[6] = {0};
#define pc (reg[4])
#define sp (reg[5])
static char truth = 0, skip = 0;

static void tick(void);

int main()
{
        fread(mem, 2, 0xffff, stdin);
        while (mem[0xffff] == 0) {
                tick();
        }
}

static word *get_arg(byte mode)
{
        byte reg_off = mode & 0x7;
        word *ptr = reg_off < 6 ? reg + reg_off : mem + pc++;
        return mode & 8 ? mem + *ptr : ptr;
}

static void write(word *dest, word value)
{
        switch (dest - mem) {
        case 0xff00: putchar(value); break;
        default: *dest = value; break;
        }
}

void tick()
{
        word code  = mem[pc++];
        byte op    = 0xf & code >> 12;
        word *arg0 = get_arg(0xf & code >> 4);
        word *arg1 = get_arg(0xf & code);
        if (skip) {
                skip = 0;
                return;
        }
        switch (op) {
        case 0x0: write(arg0, *arg1); break;
        case 0x1: write(arg0, *arg0 + *arg1); break;
        case 0x2: write(arg0, *arg0 - *arg1); break;
//        case 0x3: write(arg0, *arg1 - *arg0); break;
        case 0x4: write(arg0, *arg0 * *arg1); break;
        case 0x5: write(arg0, *arg0 * *arg1 / 0x10000); break;
        case 0x6: write(arg0, *arg0 / *arg1); break;
        case 0x7: write(arg0, *arg0 * 0x10000 / *arg1); break;
        case 0x8: write(arg0, *arg0 % *arg1); break;
        case 0x9: truth = *arg0 == *arg1; break;
        case 0xA: truth = *arg0 > *arg1; break;
//        case 0xB: truth = *arg0 >= *arg1; break;
        case 0xC: skip = truth; break;
        case 0xD: skip = !truth; break;
        case 0xE: write(mem + sp++, *arg0); break;
        case 0xF: write(arg0, mem[--sp]); break;
        }
}
