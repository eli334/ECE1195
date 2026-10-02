#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <limits.h>

#define REG_A		0 // write to A
#define REG_B		1 // write to B
#define SHAMT		2 // write to SHAMT
#define ALU_OP		3 // write to ALUOp

#define REG_R		0 // read from R
#define OVFLPORT	4 // read from overflow port
#define ZEROPORT	5 // read from zero port


#define BASE 0x70000000 // set in Vivado

static volatile uint32_t *writeMap = (volatile uint32_t *) BASE; // regmap is a uint32_t pointer to BASE
const static volatile uint32_t *readMap = (const volatile uint32_t *) BASE; // const; this is read-only, and hopefully less confusing with different variables


typedef enum {
    ALU_AND  = 0x0,
    ALU_OR   = 0x1,
    ALU_XOR  = 0x2,
    ALU_NOR  = 0x3,
    ALU_ADD  = 0x4,
    ALU_ADDU = 0x5,
    ALU_SUB  = 0x6,
    ALU_SUBU = 0x7,
	// unassigned = 0x8,
	// unassigned2 = 0x9,
    ALU_SLT  = 0xA,
    ALU_SLTU = 0xB,
    ALU_SLL  = 0xC,
    ALU_SLA  = 0xD,
    ALU_SRL  = 0xE,
    ALU_SRA  = 0xF
} alu_op_t;


static void printFail(const uint32_t A, const uint32_t B, const alu_op_t OP) {
	printf("A = %u, B = %u, OP = %d\r\n", A, B, OP);
}

static bool test_case(uint32_t A, uint32_t B, alu_op_t OP, unsigned short shiftAmt) {
	bool pass = true;
	uint32_t R, expectedR;
	bool overflow = false, zero = false, expectedOverflow = false, expectedZero = false;

	writeMap[REG_A] = A;
	writeMap[REG_B] = B;
	writeMap[SHAMT] = shiftAmt; // this just works even though it's 5 bits wide; thanks, C!
	writeMap[ALU_OP] = OP;

	expectedR = readMap[REG_R];
	expectedOverflow = readMap[OVFLPORT];
	expectedZero = readMap[ZEROPORT];

	bool a_neg = false, b_neg = false, r_neg = false;

	switch(OP) {
		// logical unit
		case ALU_AND:
			R = A & B;
			break;
		case ALU_OR:
			R = A | B;
			break;
		case ALU_XOR:
			R = A ^ B;
			break;
		case ALU_NOR:
			R = ~(A | B);
			break;
		// arith unit
		case ALU_ADD:
			R = A + B;   // uint32_t wraps exactly like the hardware adder

			a_neg = (A >> 31) & 1;
			b_neg = (B >> 31) & 1;
			r_neg = (R >> 31) & 1;

			overflow = (!a_neg && !b_neg && r_neg) || (a_neg && b_neg && !r_neg); // stolen from Arith_unit
			zero = (R == 0);
			break;
		case ALU_ADDU:
			R = A + B;

			overflow = false;
			zero = (R == 0);
			break;
		case ALU_SUB:
			R = A - B;

			a_neg = (A >> 31) & 1;
			b_neg = (B >> 31) & 1;
			r_neg = (R >> 31) & 1;

			overflow = (~a_neg & b_neg & r_neg) || (a_neg & ~b_neg & ~r_neg);
			zero = (R == 0);
			break;
		case ALU_SUBU:
			R = A - B;

			overflow = false;
			zero = (R == 0);
			break;
		// comparator unit ({0, 0}, and {0, 1} are ignored)
		case ALU_SLT:
			R = (int32_t) A < (int32_t) B; // true = 0x00000001
			break;
		case ALU_SLTU:
			R = A < B;
			break;
		// shifter unit (ignores B)
		case ALU_SLL: // technically this is the main operation, but
		case ALU_SLA: // SLA is easier to implement as existing than to just omit the opcode
			R = A << shiftAmt;
			break;
		case ALU_SRL:
			R = A >> shiftAmt;
			break;
		case ALU_SRA:
			R = ((int32_t) A) >> shiftAmt;
			break;
	}

	if(R != expectedR) {
		pass = false;
		printf("Test failed. R != expectedR.\r\n");
		printFail(A, B, OP);
	}

	if(OP >= 0x4 && OP <= 0x7) { // expectedOverflow and expectedZero might not actually match; only matter if 4 <= OP <= 7
		if(overflow != expectedOverflow) {
			pass = false;
			printf("Arith_unit gave wrong overflow response.\r\n");
			printFail(A, B, OP);
		}

		if(zero != expectedZero) {
			pass = false;
			printf("Arith_unit gave wrong zero response.\r\n");
			printFail(A, B, OP);
		}
	}

	return pass;
}

static uint32_t rand32(void) {
    return ((uint32_t)rand() << 17) ^ ((uint32_t)rand() << 4) ^ (uint32_t)rand(); // bit bash random 32 bit int together
}


int main(void) {
	srand(10000);
	bool allTestsPass = true;

	uint32_t inA = 0x00000001, inB = 0xFFFFFFFF;
	unsigned short shamt;
	alu_op_t opcode = 1;

//	bool opCode[4] = {-, -, -, -};
	/// logical unit
	// {0, 0, 0, 0} = AND
	// {0, 0, 0, 1} = OR
	// {0, 0, 1, 0} = XOR
	// {0, 0, 1, 1} = NOR
	/// arith unit
	// {0, 1, 0, 0} = ADD	(signed add)
	// {0, 1, 0, 1} = ADDU	(unsigned add)
	// {0, 1, 1, 0} = SUB 	(signed sub)
	// {0, 1, 1, 1} = SUBU	(unsigned sub)
	/// comparator
	// {1, 0, 0, 0} = unused
	// {1, 0, 0, 1} = unused
	// {1, 0, 1, 0} = SLT	(set on less than)
	// {1, 0, 1, 1} = SLTU	(set on less than unsigned)
	/// shifter
	// {1, 1, 0, 0} = SLL (shift left, logical shift)
	// {1, 1, 0, 1} = SLA (shift left, arithmetic shift; same implementation as SLL because that's just what shifting left does)
	// {1, 1, 1, 0} = SRL (shift right, logical shift)
	// {1, 1, 1, 1} = SRA (shift right, arithmetic shift)
	// this helped me make the enum table so I'm keeping it; this is all op codes on this ALU

	/// test cases

	// logic unit
	allTestsPass &= test_case(0xAAAAAAAA, 0x55555555, ALU_AND, 0);  // -> 0x00000000
	allTestsPass &= test_case(0xAAAAAAAA, 0x55555555, ALU_OR,  0);  // -> 0xFFFFFFFF
	allTestsPass &= test_case(0xF0F0F0F0, 0x0F0F0F0F, ALU_XOR, 0);  // -> 0xFFFFFFFF
	allTestsPass &= test_case(0x00000000, 0x00000000, ALU_NOR, 0);  // -> 0xFFFFFFFF

	// addition/subtraction
	allTestsPass &= test_case(0x80000000, 0x80000000, ALU_ADD,  0);  // R=0x00000000, overflow=1, zero=1
	allTestsPass &= test_case(0x7FFFFFFF, 0x00000001, ALU_ADD,  0);  // R=0x80000000, overflow=1
	allTestsPass &= test_case(0xFFFFFFFF, 0x00000001, ALU_ADDU, 0);  // R=0x00000000, overflow=0, zero=1
	allTestsPass &= test_case(0xFFFFFFFF, 0x00000001, ALU_ADD,  0);  // R=0x00000000, overflow=0, zero=1
	allTestsPass &= test_case(0x80000000, 0x00000001, ALU_SUB,  0);  // R=0x7FFFFFFF, overflow=1
	allTestsPass &= test_case(0x00000003, 0x0000000A, ALU_SUB,  0);  // 3 - A = -7 =  R=0xFFFFFFF9, overflow=0
	allTestsPass &= test_case(0x00000000, 0x00000001, ALU_SUBU, 0);  // 0 - 1 = -1 =  R=0xFFFFFFFF, overflow=0

	// comparator
	allTestsPass &= test_case(0xFFFFFFFF, 0x00000001, ALU_SLT,  0);  // R=1
	allTestsPass &= test_case(0xFFFFFFFF, 0x00000001, ALU_SLTU, 0);  // R=0
	allTestsPass &= test_case(0x00000000, 0xFFFFFFFF, ALU_SLT,  0);  // R=0  (0 < -1 is false)
	allTestsPass &= test_case(0x00000000, 0xFFFFFFFF, ALU_SLTU, 0);  // R=1  (0 < 2^32-1 is true)
	allTestsPass &= test_case(0x00000005, 0x00000005, ALU_SLT,  0);  // R=0 (equality should give 0)

	// shifter

	allTestsPass &= test_case(0x80000000, 0x00000000, ALU_SRL, 4);  // R=0x08000000
	allTestsPass &= test_case(0x80000000, 0x00000000, ALU_SRA, 4);  // R=0xF8000000

	// shift-by-zero does nothing
	allTestsPass &= test_case(0x12345678, 0x00000000, ALU_SLL, 0);  // R=0x12345678
	allTestsPass &= test_case(0x80000000, 0x00000000, ALU_SRA, 0);  // R=0x80000000

	// full 31-bit shift, exercises every stage of the barrel shifter at once
	allTestsPass &= test_case(0x00000001, 0x00000000, ALU_SLL, 31); // R=0x80000000

	allTestsPass &= test_case(0xDEADBEEF, 0x00000000, ALU_SLL, 5);  // R=0xD5B7DDE0
	allTestsPass &= test_case(0xDEADBEEF, 0x00000000, ALU_SLA, 5);  // R=0xD5B7DDE0


	// random tests
	// we didn't assign two ops, so this is a little annoying:

	const alu_op_t valid_ops[] = {
	    ALU_AND, ALU_OR, ALU_XOR, ALU_NOR,
	    ALU_ADD, ALU_ADDU, ALU_SUB, ALU_SUBU,
	    ALU_SLT, ALU_SLTU,
	    ALU_SLL, ALU_SLA, ALU_SRL, ALU_SRA
	};

	const int num_ops = sizeof(valid_ops) / sizeof(valid_ops[0]); // 14, but this is proper form
	allTestsPass &= test_case(inA, inB, ALU_AND, 0);

	for (int i = 0; i < 1000; i++) {
	    uint32_t A = rand32();
	    uint32_t B = rand32();
	    alu_op_t OP = valid_ops[rand() % num_ops];
	    unsigned short shamt = rand() % 32; // ignored unless it's a shifter opcode; generated anyway

	    allTestsPass &= test_case(A, B, OP, shamt);
	}

	if(allTestsPass) {
		printf("All tests passed! Yippee!\r\n");
	}
}
