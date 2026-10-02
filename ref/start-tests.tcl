set headless 1

set candidates [lsort [glob -nocomplain -directory C:/dev/ECE1195 -- */tcl/ee_test*.tcl]]

if {[llength $candidates] == 0} {
    puts "No tests found."
} else {
    puts "Which test?"
    set i 1
    foreach f $candidates {
        puts "  $i) $f"
        incr i
    }

    puts -nonewline "> "
    flush stdout
    set choice [gets stdin]
	puts "DEBUG: gets returned -->$choice<--"    ;# add this line

    if {[string is integer -strict $choice] && $choice >= 1 && $choice <= [llength $candidates]} {
        set chosen [lindex $candidates [expr {$choice - 1}]]
        cd [file dirname $chosen]
		puts -nonewline "Headless? (1 = yes, 0 = show waveforms): "
		
		flush stdout
		set headless [gets stdin]
		
        source [file tail $chosen]
    } else {
        puts "Invalid choice."
    }
}