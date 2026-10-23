set TB     /ee_cpu_tb
set CPU    $TB/U_0
set REGS   $CPU/datapath/regfile/regs     ;# register file array
set STATE  $CPU/control/state    ;# FSM state signal
set MAXCYC 40                    ;# give up after this many cycles

set results {}

proc reg {n} { return "$::REGS\[$n\]" }

# Numeric compare of two hex strings; anything with U/X just compares unequal
proc same {a b} { expr {"0x$a" == "0x$b"} }

# Reset, force source registers ({n value n value ...}), put instr on MemoryDataIn
proc setup {instr regs} {
    restart
    remove_forces -all
    add_force $::TB/Clock {0 0ns} {1 5ns} -repeat_every 10ns
    add_force $::TB/Reset {1 0ns} {0 10ns}
    set ::memf [add_force $::TB/MemoryDataIn -radix hex [list $instr 0ns]]
    foreach {n val} $regs {
        add_force [reg $n] -radix hex [list $val 0ns]
    }
    run 10ns    ;# reset released; the first FETCH edge is at 15 ns
}

# Run until the FSM returns to FETCH. Returns the cycle count, or -1 on timeout.
# If memdata is given, MemoryDataIn switches to it after FETCH (acts as data memory).
# Any memory writes are recorded in ::memwrites as {address data ...}.
proc run_instr {{memdata ""}} {
    set ::memwrites {}
    run 10ns                                ;# FETCH
    if {$memdata ne ""} {
        remove_forces $::memf
        add_force $::TB/MemoryDataIn -radix hex [list $memdata 0ns]
    }
    set cycles 1
    while {![string equal -nocase [get_value $::STATE] fetch]} {
        if {[get_value $::TB/MemWrite] eq "1"} {
            lappend ::memwrites [get_value -radix hex $::TB/MemoryAddress] \
                                [get_value -radix hex $::TB/MemoryDataOut]
        }
        run 10ns
        incr cycles
        if {$cycles > $::MAXCYC} { return -1 }
    }
    return $cycles
}

# 2 cycles means DECODE went straight back to FETCH: the opcode wasn't recognized
proc record {name ok cycles detail} {
    if {$cycles == -1} {
        set status TIMEOUT
    } elseif {$cycles == 2} {
        set status "NOT DECODED"
    } elseif {$ok} {
        set status PASS
    } else {
        set status FAIL
    }
    lappend ::results [list $name $status $cycles $detail]
}

# Check a register after the instruction
proc test_reg {name instr regs n expected {memdata ""}} {
    setup $instr $regs
    set c [run_instr $memdata]
    set actual [get_value -radix hex [reg $n]]
    record $name [same $actual $expected] $c "\$$n = $actual (expected $expected)"
}

# Check that exactly one memory write happened, with this address and data
proc test_store {name instr regs addr data} {
    setup $instr $regs
    set c [run_instr]
    set ok [expr {[llength $::memwrites] == 2
                  && [same [lindex $::memwrites 0] $addr]
                  && [same [lindex $::memwrites 1] $data]}]
    record $name $ok $c "writes {addr data}: $::memwrites (expected $addr $data)"
}

# Check the PC afterward (during FETCH, MemoryAddress = PC)
proc test_pc {name instr regs expected} {
    setup $instr $regs
    set c [run_instr]
    set pc [get_value -radix hex $::TB/MemoryAddress]
    record $name [same $pc $expected] $c "PC = $pc (expected $expected)"
}

# ---- Tests ----
#          name  instruction  forced regs                  check
test_reg   ADDI  20430005  {2 0000000A}                   3 0000000F  ;# addi $3, $2, 5
test_reg   ORI   34438000  {2 00000001}                   3 00008001  ;# ori  $3, $2, 0x8000 (zero-extend)
test_reg   SLTI  2843FFFF  {2 FFFFFFFB}                   3 00000001  ;# slti $3, $2, -1 (-5 < -1)
test_reg   LUI   3C031234  {}                             3 12340000  ;# lui  $3, 0x1234
test_reg   ADDU  00432021  {2 0000000A 3 00000014}        4 0000001E  ;# addu $4, $2, $3
test_reg   LW    8C430004  {2 00000100}                   3 CAFEF00D CAFEF00D ;# lw $3, 4($2)
test_store SW    AC430004  {2 00000100 3 DEADBEEF}        00000104 DEADBEEF   ;# sw $3, 4($2)
test_pc    BNE   14430003  {2 00000001 3 00000002}        00000010            ;# bne $2, $3, 3 (taken)
# Add the rest here; assemble each one in MARS and copy the hex from the Execute tab.

# ---- Summary ----
set passed 0
puts "\n========== Instruction tests =========="
foreach r $results {
    lassign $r name status cycles detail
    if {$status eq "PASS"} { incr passed }
    set note ""
    if {$cycles > 5 && $name ne "MULTU"} { set note "  <-- over the 5-cycle limit" }
    puts [format "%-6s %-12s %3s cycles   %s%s" $name $status $cycles $detail $note]
}
puts "$passed / [llength $results] passing\n"
quit