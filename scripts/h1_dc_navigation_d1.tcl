# H1 entry: synthesize navigation_d1 with its NH and word-sync instances.
# Run only after d1_word_sync and nh20_sync have mapped.
# Run from work/h1_dc_nav:
#   dc_shell -f ../../scripts/h1_dc_navigation_d1.tcl

set H1_TOP navigation_d1
set H1_SOURCES [list \
  ../../student_release/student_release/rtl/d1_word_sync.sv \
  ../../student_release/student_release/rtl/nh20_sync.sv \
  ../../student_release/student_release/rtl/navigation_d1.sv]
source ../../scripts/h1_dc_common.tcl
