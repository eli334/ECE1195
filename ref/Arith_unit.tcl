# restart the simulation
restart

####################################
# set A to FFFFFFFF

add_force /Arith_Unit/A -radix hex FFFFFFFF

# you can also name the signal directly without having to specify which entity it belongs to, like
# add_force A -radix hex FF
#
# if you want to specify the value in binary, you can also drop the radix part and write it in binary directly, like
# add_force A 11111111
#
# other allowed radices: dec, bin, oct, hex, unsigned.
#
# if you want to specify the value of a certain bit, you can:
# add_force A(0) 0
#
# if you want to specify the value of a certain bit range, you can do:
# add_force A(1:0) 10


####################################
# set B to 01

add_force /Arith_Unit/B 01

####################################
# set C_op to 01 (ADD Unsigned)

add_force /Arith_Unit/C_op 01

####################################
# run simulation for 10 ns

run 10 ns

# not specifying units will use the default units. the default unit is ns
# the units can be:
# ps: pecoseconds
# ns: nanoseconds
# us: microseconds
# ms: milliseconds
# s :  seconds

# set C_op to 01 (SUB Unsigned)
add_force /Arith_Unit/C_op 11

run 10 ns
