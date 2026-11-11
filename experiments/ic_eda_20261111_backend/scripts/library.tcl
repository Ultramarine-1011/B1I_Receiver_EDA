# Library-only entry. No design is read here.
set_app_var sh_enable_page_mode false
set_host_options -max_cores 1
set_app_var target_library [list $env(STD_DB)]
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [concat [list * $env(STD_DB) dw_foundation.sldb] $env(EXTRA_LINK_DB)]
set_app_var search_path [concat [list rtl sources/student_release/student_release/rtl .] $search_path]
define_design_lib WORK -path ./WORK
