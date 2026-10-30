# H1 entry: synthesize d1_word_sync alone.
# Run from work/h1_dc_d1:
#   dc_shell -f ../../scripts/h1_dc_d1_word_sync.tcl

set H1_TOP d1_word_sync
set H1_SOURCES [list ../../student_release/student_release/rtl/d1_word_sync.sv]
source ../../scripts/h1_dc_common.tcl
