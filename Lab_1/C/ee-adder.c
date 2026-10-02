#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

#define REG_A     0   // write numA;  read numSum
#define REG_B     1   // write numB
#define REG_LED   2   // write led;   read btn
#define REG_SUB   3   // write sub
#define REG_CARRY 4   // read Carry_out

#define BASE 0x70000000

static volatile uint32_t *regmap = (volatile uint32_t *) BASE; // base address of axi_regmap as set in the Vivado address editor

static bool test_case(uint32_t a, uint32_t b, bool sub) {
    uint32_t expected_sum, expected_carry, adder_sum, adder_carry;
    bool pass = true;

    regmap[REG_A] = a;
    regmap[REG_B] = b;
    regmap[REG_SUB] = sub;

    adder_sum = regmap[REG_A];
    adder_carry = regmap[REG_CARRY];

    if(sub) {
        expected_sum = a - b;
        if(a >= b) expected_carry = 1u;
        else expected_carry = 0u;
    } else {
        expected_sum = a + b;
        if(a + b < a) { // overflow check; if true, it overflowed
            expected_carry = 1u;
        } else expected_carry = 0u;
    }

    if(expected_sum != adder_sum) {
        printf("Expected sum and adder sum are different!\r\n");
        printf("a = %lu, b = %lu\r\nadder_sum = %lu, expected_sum = %lu\r\n", a, b, adder_sum, expected_sum);
        pass = false;
    }

    if(expected_carry != adder_carry){
        printf("Expected carry and adder carry are different!\r\n");
        printf("a = %lu, b = %lu\r\nadder_carry = %lu, expected_carry = %lu\r\n", a, b, adder_carry, expected_carry);
        pass = false;
    }
    return pass;
}

static bool test_random_values(int numIterations, int seed, bool subtraction) {
    uint32_t A, B;
    bool allPass = true;
    int i = 0;
    srand(seed);

    A = rand();
    B = rand();

    for(i = 0; i < numIterations; i++) {
        allPass &= test_case(A, B, subtraction);
        if(!allPass) {
            break;
        }
    }

    if(!allPass) {
        printf("Test case %d/%d failed.\r\n", i, numIterations);
    } else printf("All %d %s cases successful!\r\n", numIterations, ((subtraction) ? "subtraction" : "addition"));


    return allPass;
}

int main(void)
{
    bool allPass = true;

    /* addition */
    allPass &= test_case(0x00000001, 0x00000000, false);  /* S=00000001 C=0 */
    allPass &= test_case(0xFFFFFFFF, 0x00000001, false);  /* S=00000000 C=1 */
    allPass &= test_case(0x7FFFFFFF, 0x00000001, false);  /* S=80000000 C=0 */
    allPass &= test_case(0xAAAAAAAA, 0x55555555, false);  /* S=FFFFFFFF C=0 */
    allPass &= test_case(0x80000000, 0x80000000, false);  /* S=00000000 C=1 */
    allPass &= test_case(0x00000000, 0x00000000, false);  /* S=00000000 C=0 */
    /* subtraction */
    allPass &= test_case(0x0000000A, 0x00000003, true);   /* S=00000007 C=1 */
    allPass &= test_case(0x12345678, 0x12345678, true);   /* S=00000000 C=1 */
    allPass &= test_case(0x00000003, 0x0000000A, true);   /* S=FFFFFFF9 C=0 */
    allPass &= test_case(0xABCDDCBA, 0x00000000, true);   /* S=ABCDDCBA C=1 */

    if(!allPass) {
        printf("A test case failed!\r\n");
    }
    allPass = true;


    allPass &= test_random_values(1000, 123, false); // addition tests
    allPass &= test_random_values(1000, 123, true); // subtraction tests with the same numbers

    allPass &= test_random_values(10000, 8792435, true); // random seed


    return 0;
}