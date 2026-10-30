# H1 entry: synthesize nh20_sync alone.
# Run from work/h1_dc_nh:
#   dc_shell -f ../../scripts/h1_dc_nh20_sync.tcl

set H1_TOP nh20_sync
set H1_SOURCES [list ../../student_release/student_release/rtl/nh20_sync.sv]
source ../../scripts/h1_dc_common.tcl
