# verify-all.tcl -- load the all-instructions program into cpu_tb's memory, run it
# until it writes its end marker, then check every result word.
#
# Run with cpu_tb as the top (batch or GUI). In GUI mode (EE_GUI set by xsim.ps1)
# the window stays open afterward so you can look at the waveform.

set HEX     C:/dev/ECE1195/lab_files/Lab_4/mips/full-program.hex
set TB      /cpu_tb
set MEM     $TB/U_1/mw_U_0ram_table
set CLK     $TB/clock               ;# the handout requires cpu_tb's ports to be clock and reset
set RST     $TB/reset
set MAXNS   20000                   ;# give up after this much simulated time (2000 cycles)
set GUI     [info exists ::env(EE_GUI)]

# address (hex)  expected (hex)  description
set expected {
    2000 00000011 "ADDI positive"
    2004 FFFFFFFD "ADDI negative"
    2008 00000002 "ADDI reg + imm (SW base + negative offset)"
    200C 00000015 "ORI small immediate"
    2010 00008000 "ORI zero-extend"
    2014 00000001 "SLTI -5 < -1"
    2018 00000000 "SLTI -5 < -10"
    201C 00000001 "SLTI -5 < 1"
    2020 12340000 "LUI"
    2024 FFFF0000 "LUI upper bit set"
    2028 0000000E "ADDU"
    202C 80000000 "ADDU signed overflow, no trap"
    2030 0000000F "AND"
    2034 00000014 "SUB"
    2038 FFFFFFEC "SUB negative result"
    203C 00000110 "SLL"
    2040 80000000 "SLL by 31"
    2044 FFFFFFFC "SRA negative (fills with ones)"
    2048 00000008 "SRA positive"
    204C 00000060 "SLLV"
    2050 00000006 "SLLV amount masked to 5 bits"
    2054 CAFEF00D "word for LW"
    2058 CAFEF00D "LW"
    205C 80017FFF "word for LH"
    2060 00007FFF "LH low half, positive"
    2064 FFFF8001 "LH high half, sign-extended"
    2068 0000000C "CLO"
    206C 00000020 "CLO all ones"
    2070 00000000 "CLO none"
    2074 00000002 "MFHI"
    2078 FFFFFFFD "MFLO"
    207C 0000000A "BNE taken"
    2080 0000600D "BNE not taken"
    2084 00000003 "BNE backward loop"
    2088 00000001 "J"
    208C 00000001 "JR"
    2090 00000D0E "end marker"
}
set END_ADDR 2090
set END_MARK 00000D0E

# Word index for a byte address given in hex (e.g. 2090 -> 2084)
proc word {addr} { return [expr {[scan $addr %x] / 4}] }

# Memory word at a byte address given in hex
proc mem {addr} {
    return [get_value -radix hex "$::MEM\[[word $addr]\]"]
}

# Numeric compare of two hex strings; anything with U/X just compares unequal
proc same {a b} { expr {"0x$a" == "0x$b"} }

proc load_hex {file} {
    set f [open $file r]
    set i 0
    while {[gets $f line] >= 0} {
        set line [string trim $line]
        if {$line eq ""} continue
        add_force "$::MEM\[$i\]" -radix hex $line
        incr i
    }
    close $f
    puts "Loaded $i words from $file"
}

# ---- Load, reset, run ----
restart
if {$GUI} { log_wave -r / }
load_hex $HEX
add_force $CLK {0 0ns} {1 5ns} -repeat_every 10ns
add_force $RST {1 0ns} {0 20ns}

set t 0
while {![same [mem $END_ADDR] $END_MARK] && $t < $MAXNS} {
    run 100ns
    incr t 100
}
if {[same [mem $END_ADDR] $END_MARK]} {
    puts "\nEnd marker written by ~$t ns (about [expr {$t / 10}] cycles)."
} else {
    puts "\nEnd marker never written after $MAXNS ns: the CPU got stuck, or a"
    puts "branch/jump went astray. The results below show how far it got."
}

# ---- Check ----
set passed 0
set total  0
puts "\n========== all_instructions results =========="
foreach {addr want desc} $expected {
    set got [mem $addr]
    incr total
    if {[same $got $want]} {
        incr passed
        puts [format "PASS  \[%s\] (word %4d)  %s  %s" $addr [word $addr] $got $desc]
    } else {
        puts [format "FAIL  \[%s\] (word %4d)  %s  expected %s  %s" \
                  $addr [word $addr] $got $want $desc]
    }
}
puts "$passed / $total checks passed\n"

if {!$GUI} { quit }