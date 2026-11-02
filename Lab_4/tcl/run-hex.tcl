proc load_hex {file} {
    set f [open $file r]
    set i 0
    while {[gets $f line] >= 0} {
        set line [string trim $line]
        if {$line eq ""} continue
        add_force "/cpu_tb/U_1/mw_U_0ram_table\[$i\]" -radix hex $line
        incr i
    }
    close $f
    puts "Loaded $i words from $file"
}

load_hex C:/dev/ECE1195/lab_files/Lab_4/mips/full-program.hex

#forcing a clock with 10 ns period
add_force clk 1 {0 5ns} -repeat_every 10ns

#give a reset signal
add_force reset 0
run 2500ps
add_force reset 1
run 5 ns
add_force reset 0

run 200 ns