addi  $1, $0, -1        # 0xFFFFFFFF
addi  $2, $0, 3
multu $1, $2            # 0x00000002_FFFFFFFD
mfhi  $3
mflo  $4
sw    $3, 52($0)        # word 12
sw    $4, 56($0)        # word 13
multu $1, $1            # 0xFFFFFFFE_00000001: checks a second MULTU restarts cleanly
mfhi  $5
mflo  $6
sw    $5, 60($0)        # word 14
sw    $6, 64($0)        # word 15
done: J done