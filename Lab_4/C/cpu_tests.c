//#include "xparameters.h"
//#include "xil_cache.h"
//#include "xtime_l.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
//#include "sleep.h"

#define BRAM_DEPTH           32           // words loaded/cleared each run (results live in words 16-18)
#define BRAM_CONTROLLER_ADDR 0x41000000
#define LAB_CPU_ADDR         0x40000000

#define HI_WORD    16                     // sw $3, 64($0)
#define LO_WORD    17                     // sw $4, 68($0)
#define DONE_WORD  18                     // sw $5, 72($0): written last
#define DONE_MARK  0x00000D0E
#define MAX_POLLS  100000                 // each poll is a slow AXI read; MULTU needs ~40 cycles
#define NUM_RANDOM 100


static volatile uint32_t *const bram = (volatile uint32_t *) BRAM_CONTROLLER_ADDR;
static volatile uint32_t *const cpu  = (volatile uint32_t *) LAB_CPU_ADDR;

uint32_t get_random_32bit(void) {
    uint32_t b0 = rand() & 0x7FFF;
    uint32_t b1 = rand() & 0x7FFF;
    uint32_t b2 = rand() & 0x7FFF;

    // 15 bits + 15 bits + 2 bits = 32 bits of entropy
    return (b0 << 17) | (b1 << 2) | (b2 & 0x03);
}

// Builds and runs a program that computes HI:LO = a * b on the CPU.
// Returns false if the CPU never wrote the done marker.
static bool run_mult(uint32_t a, uint32_t b, uint32_t *hi, uint32_t *lo) {
    const uint32_t program[] = {
        0x3C010000 | (a >> 16),       // lui   $1, upper(a)
        0x34210000 | (a & 0xFFFF),    // ori   $1, $1, lower(a)
        0x3C020000 | (b >> 16),       // lui   $2, upper(b)
        0x34420000 | (b & 0xFFFF),    // ori   $2, $2, lower(b)
        0x00220019,                   // multu $1, $2
        0x00001810,                   // mfhi  $3
        0x00002012,                   // mflo  $4
        0xAC030040,                   // sw    $3, 64($0)      -> word 16
        0xAC040044,                   // sw    $4, 68($0)      -> word 17
        0x20050D0E,                   // addi  $5, $0, 0xD0E
        0xAC050048,                   // sw    $5, 72($0)      -> word 18 (done)
        0x0800000B,                   // done: j done          (halt at address 44)
    };
    const int n = sizeof program / sizeof program[0];

    cpu[0] = 1;                                   // hold the CPU in reset while loading
    for (int i = 0; i < BRAM_DEPTH; ++i)
        bram[i] = (i < n) ? program[i] : 0;       // program, then clear old results/marker
    cpu[0] = 0;                                   // release reset: CPU starts at PC = 0

    int polls = 0;
    while (bram[DONE_WORD] != DONE_MARK && polls < MAX_POLLS)
        ++polls;
    cpu[0] = 1;                                   // stop the CPU before reading results

    if (bram[DONE_WORD] != DONE_MARK)
        return false;
    *hi = bram[HI_WORD];
    *lo = bram[LO_WORD];
    return true;
}

// Runs one multiplication on the CPU and compares it against C's 64-bit product.
static bool check(uint32_t a, uint32_t b) {
    uint64_t expected = (uint64_t) a * b;         // cast first, or C gives a 32 bit result
    uint32_t exp_hi = (uint32_t) (expected >> 32);
    uint32_t exp_lo = (uint32_t) expected;
    uint32_t hi, lo;

    if (!run_mult(a, b, &hi, &lo)) {
        printf("TIMEOUT  a = 0x%08X  b = 0x%08X  (done marker never written)\r\n",
               (unsigned) a, (unsigned) b);
        return false;
    }
    if (hi == exp_hi && lo == exp_lo)
        return true;

    printf("FAIL     a = 0x%08X  b = 0x%08X  got HI:LO = %08X:%08X  expected %08X:%08X\r\n",
           (unsigned) a, (unsigned) b, (unsigned) hi, (unsigned) lo,
           (unsigned) exp_hi, (unsigned) exp_lo);
    return false;
}

int main(void) {
    const uint32_t edge_cases[][2] = {
        {0x00000000, 0x12345678},
        {0x00000001, 0xFFFFFFFF},
        {0xFFFFFFFF, 0xFFFFFFFF},
        {0x80000000, 0x00000002},
        {0xFFFFFFFF, 0x00000003},
        {0x0000FFFF, 0x0000FFFF},
        {0x00008000, 0x00008000},
    };
    const int num_edge_cases = sizeof edge_cases / sizeof edge_cases[0];
    int passed = 0, total = 0;

    printf("-------------------------------------\r\n");
    printf("MULTU / MFHI / MFLO test\r\n");

    for (int i = 0; i < num_edge_cases; ++i, ++total)
        passed += check(edge_cases[i][0], edge_cases[i][1]);

    srand(1293248); 	// fixed seed
    for (int i = 0; i < NUM_RANDOM; ++i, ++total)
        passed += check(get_random_32bit(), get_random_32bit());

    printf("%d / %d multiplications correct\r\n", passed, total);
    return 0;
}
