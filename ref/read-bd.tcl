# Recreate every block design in lab_files/<lab>/bd/ inside the open project
# Usage (Vivado Tcl console): source C:/dev/ECE1195/lab_files/ref/read-bd.tcl
# Run in a project that doesn't already have these block designs (fresh project).

set rbd_root [file dirname [file dirname [file normalize [info script]]]]
set rbd_lab  [file tail [get_property DIRECTORY [current_project]]]
set rbd_in   [file join $rbd_root $rbd_lab bd]

set rbd_scripts [glob -nocomplain -directory $rbd_in *.tcl]
if {[llength $rbd_scripts] == 0} {
    error "No block design scripts in $rbd_in"
}

foreach rbd_script $rbd_scripts {
    puts "Importing $rbd_script"
    source $rbd_script
}
puts "Done. Right-click each design -> Create HDL Wrapper."
