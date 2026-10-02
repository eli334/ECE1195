#include <stdio.h>
#include <stdlib.h>

/*int main(void)
{
	uint32_t *regmap = (uint32_t *) 0x70000000; // base address of axi_regmap as set in the Vivado address editor

	uint64_t  res = 0, reg; // 64-bit register to hold the value of the multiplication and the result from the multiplier
	uint32_t  A, B;	// 32-bit random numbers

	A = rand();
	B = rand();
	res = (uint64_t) A * (uint64_t) B; // you have to do type casting before multiplying, otherwise, you will end up having incorrect result.

	// Assign A, B to your multiplier

	// give the reset signal

	// poll for done signal

	// assuming your result is stored in R_high = regmap[1] and R_low = regmap[0]
	// you have to do type casting first, othersie you will end up with a wrong answer.
	reg = (((uint64_t) regmap[1]) << 32) + ((uint64_t) regmap[0]);

	// %8lx will print uint32_t in hex in 8 digits, %16llx will print uint64_t in hex in 16 digits.

	printf("%8lx * %8lx = %8lx%8lx (%16llx) (%s) \n\n", A, B, regmap[1], regmap[0], res, (reg == res ? "correct" : "wrong"));

	return 0;
}*/
