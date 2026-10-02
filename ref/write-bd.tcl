# Export every block design in the open project to lab_files/<lab>/bd/<name>.tcl
# Usage (Vivado Tcl console): source C:/dev/ECE1195/lab_files/ref/write-bd.tcl
# <lab> is the Vivado project folder name, so Vivado/Lab_4 -> lab_files/Lab_4/bd

set wbd_root [file dirname [file dirname [file normalize [info script]]]]
set wbd_lab  [file tail [get_property DIRECTORY [current_project]]]
set wbd_out  [file join $wbd_root $wbd_lab bd]

if {![file isdirectory [file join $wbd_root $wbd_lab]]} {
    error "No folder [file join $wbd_root $wbd_lab]; project folder name must match the lab folder"
}
set wbd_files [get_files -quiet *.bd]
if {[llength $wbd_files] == 0} {
    error "No block designs in project $wbd_lab"
}

file mkdir $wbd_out
foreach wbd_file $wbd_files {
    set wbd_name [file rootname [file tail $wbd_file]]
    open_bd_design $wbd_file
    write_bd_tcl -force [file join $wbd_out $wbd_name.tcl]
    puts "Exported $wbd_name -> [file join $wbd_out $wbd_name.tcl]"
}
