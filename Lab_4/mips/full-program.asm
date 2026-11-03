# All 20 instructions in one program (119 instructions).
#
# MARS settings: turn off pseudo-instructions, and set Memory Configuration to
# 'Compact, Text at Address 0'. Results are stored with $28 = 0x2000 as the base,
# which is the .data segment in that configuration.
#
# Control flow (BNE, J, JR) is tested last, so a bad branch can't skip earlier checks.
# The last result (0xD0E at 0x2090) means the program reached the end, after which
# it halts in a 'j done' loop (with a BNE backup in case J doesn't work).
#
# Expected memory afterward:
#   address     value       check
#   0x00002000  0x00000011  ADDI positive
#   0x00002004  0xFFFFFFFD  ADDI negative
#   0x00002008  0x00000002  ADDI reg + imm (stored with SW base + negative offset)
#   0x0000200C  0x00000015  ORI small immediate
#   0x00002010  0x00008000  ORI zero-extend
#   0x00002014  0x00000001  SLTI -5 < -1
#   0x00002018  0x00000000  SLTI -5 < -10
#   0x0000201C  0x00000001  SLTI -5 < 1
#   0x00002020  0x12340000  LUI
#   0x00002024  0xFFFF0000  LUI upper bit set
#   0x00002028  0x0000000E  ADDU
#   0x0000202C  0x80000000  ADDU signed overflow, no trap
#   0x00002030  0x0000000F  AND
#   0x00002034  0x00000014  SUB
#   0x00002038  0xFFFFFFEC  SUB negative result
#   0x0000203C  0x00000110  SLL
#   0x00002040  0x80000000  SLL by 31
#   0x00002044  0xFFFFFFFC  SRA negative (fills with ones)
#   0x00002048  0x00000008  SRA positive
#   0x0000204C  0x00000060  SLLV				-- broken on first pass
#   0x00002050  0x00000006  SLLV amount masked to 5 bits	-- broken on first pass
#   0x00002054  0xCAFEF00D  word for LW
#   0x00002058  0xCAFEF00D  LW
#   0x0000205C  0x80017FFF  word for LH (0x80017FFF)
#   0x00002060  0x00007FFF  LH low half, positive		-- broken on first pass
#   0x00002064  0xFFFF8001  LH high half, sign-extended	-- broken on first pass
#   0x00002068  0x0000000C  CLO
#   0x0000206C  0x00000020  CLO all ones
#   0x00002070  0x00000000  CLO none
#   0x00002074  0x00000002  MFHI				-- broken on first pass
#   0x00002078  0xFFFFFFFD  MFLO				-- broken on first pass
#   0x0000207C  0x0000000A  BNE taken
#   0x00002080  0x0000600D  BNE not taken
#   0x00002084  0x00000003  BNE backward loop
#   0x00002088  0x00000001  J
#   0x0000208C  0x00000001  JR
#   0x00002090  0x00000D0E  end marker
#
# 0xBAD anywhere means a branch or jump went the wrong way.

        .text
        addi $28, $0, 0x2000    # results base (never changed)

# ---- ADDI + SW
        addi $1, $0, 17         # 17
        addi $2, $0, -3         # -3 (sign-extended immediate)
        addi $3, $2, 5          # 2
        sw   $1, 0($28)         # R0  ADDI positive
        sw   $2, 4($28)         # R1  ADDI negative
        addi $4, $28, 12
        sw   $3, -4($4)         # R2  ADDI reg+imm, SW base + negative offset

# ---- ORI, SLTI, LUI
        addi $1, $0, 16
        ori  $2, $1, 0x0005     # 0x15
        ori  $3, $0, 0x8000     # 0x00008000 (zero-extended)
        sw   $2, 12($28)        # R3  ORI small immediate
        sw   $3, 16($28)        # R4  ORI zero-extend
        addi $1, $0, -5
        slti $2, $1, -1         # 1
        slti $3, $1, -10        # 0
        slti $4, $1, 1          # 1
        sw   $2, 20($28)        # R5  SLTI -5 < -1
        sw   $3, 24($28)        # R6  SLTI -5 < -10
        sw   $4, 28($28)        # R7  SLTI -5 < 1
        lui  $1, 0x1234
        lui  $2, 0xFFFF
        sw   $1, 32($28)        # R8  LUI
        sw   $2, 36($28)        # R9  LUI upper bit set

# ---- ADDU, AND, SUB
        addi $1, $0, 17
        addi $2, $0, -3
        addu $3, $1, $2         # 14
        lui  $4, 0x7FFF
        ori  $4, $4, 0xFFFF     # 0x7FFFFFFF
        addi $5, $0, 1
        addu $6, $4, $5         # 0x80000000, must not trap
        sw   $3, 40($28)        # R10 ADDU
        sw   $6, 44($28)        # R11 ADDU signed overflow, no trap
        ori  $1, $0, 0x00FF
        ori  $2, $0, 0x0F0F
        and  $3, $1, $2         # 0x0F
        sw   $3, 48($28)        # R12 AND
        addi $1, $0, 17
        addi $2, $0, -3
        sub  $3, $1, $2         # 20
        sub  $4, $2, $1         # -20
        sw   $3, 52($28)        # R13 SUB
        sw   $4, 56($28)        # R14 SUB negative result

# ---- SLL, SRA, SLLV
        addi $1, $0, 0x11
        sll  $2, $1, 4          # 0x110
        sll  $3, $1, 31         # 0x80000000
        sw   $2, 60($28)        # R15 SLL
        sw   $3, 64($28)        # R16 SLL by 31
        addi $1, $0, -16
        sra  $2, $1, 2          # -4
        addi $3, $0, 64
        sra  $4, $3, 3          # 8
        sw   $2, 68($28)        # R17 SRA negative (fills with ones)
        sw   $4, 72($28)        # R18 SRA positive
        addi $1, $0, 3
        addi $2, $0, 5
        sllv $3, $1, $2         # 96
        addi $4, $0, 33
        sllv $5, $1, $4         # 6 (only low 5 bits of rs)
        sw   $3, 76($28)        # R19 SLLV
        sw   $5, 80($28)        # R20 SLLV amount masked to 5 bits

# ---- LW, LH
        lui  $1, 0xCAFE
        ori  $1, $1, 0xF00D
        sw   $1, 84($28)        # R21 word for LW
        addi $2, $28, 80
        lw   $3, 4($2)          # loads R21 through a different base + offset
        sw   $3, 88($28)        # R22 LW
        lui  $1, 0x8001
        ori  $1, $1, 0x7FFF
        sw   $1, 92($28)        # R23 word for LH (0x80017FFF)
        lh   $2, 92($28)        # low half  -> 0x00007FFF
        lh   $3, 94($28)        # high half -> 0xFFFF8001
        sw   $2, 96($28)        # R24 LH low half, positive
        sw   $3, 100($28)       # R25 LH high half, sign-extended

# ---- CLO
        lui  $1, 0xFFF0
        clo  $2, $1             # 12
        addi $3, $0, -1
        clo  $4, $3             # 32
        addi $5, $0, 1
        clo  $6, $5             # 0
        sw   $2, 104($28)       # R26 CLO
        sw   $4, 108($28)       # R27 CLO all ones
        sw   $6, 112($28)       # R28 CLO none

# ---- MULTU, MFHI, MFLO
        addi  $1, $0, -1
        addi  $2, $0, 3
        multu $1, $2            # 0x2_FFFFFFFD (unsigned)
        mfhi  $3
        mflo  $4
        sw    $3, 116($28)      # R29 MFHI
        sw    $4, 120($28)      # R30 MFLO

# ---- BNE
        addi $5, $0, 0xA
        addi $6, $0, 0
        addi $1, $0, 1
        addi $2, $0, 2
        bne  $1, $2, b_taken    # should branch
        addi $5, $0, 0xBAD      # skipped
b_taken: bne $1, $1, b_skip     # should fall through
        addi $6, $0, 0x600D
b_skip: sw   $5, 124($28)       # R31 BNE taken
        sw   $6, 128($28)       # R32 BNE not taken
        addi $7, $0, 3
        addi $8, $0, 0
b_loop: addi $8, $8, 1
        addi $7, $7, -1
        bne  $7, $0, b_loop
        sw   $8, 132($28)       # R33 BNE backward loop

# ---- J, JR
        addi $5, $0, 1
        j    j_over
        addi $5, $0, 0xBAD      # skipped
j_over: sw   $5, 136($28)       # R34 J
        addi $5, $0, 1
        addi $1, $0, 456  # address of jr_over (filled in by the build)
        jr   $1
        addi $5, $0, 0xBAD      # skipped
jr_over: sw  $5, 140($28)       # R35 JR

# ---- done: R36 marks that the program reached the end, then halt
        addi $5, $0, 0xD0E
        sw   $5, 144($28)       # R36 end marker
done:   j    done
        bne  $28, $0, done      # backup halt if J doesn't work
