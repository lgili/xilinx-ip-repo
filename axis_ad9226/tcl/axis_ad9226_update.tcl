# Source metadata
source ./tcl/metadata.tcl

# Open project
set ip_project [ open_project ${proj_dir}/${design}.xpr ]

#ipx::package_project
##set ip_core [ipx::current_core]
#ipx::check_integrity ${ip_core}

ipx::edit_ip_in_project -upgrade true -name ${design}_project  -directory ${proj_dir}


ipx::merge_project_changes files [ipx::current_core]
ipx::merge_project_changes ports [ipx::current_core]

set version [get_property core_revision [ipx::current_core]]
puts "======================================"
puts "Old version of IP is $version"
puts "======================================"
set_property core_revision [expr [get_property core_revision [ipx::current_core]] \+ 1] [ipx::current_core]
set version [get_property core_revision [ipx::current_core]]
puts "======================================"
puts "Current version of IP is $version"
puts "======================================"



ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]

puts "======================================"
puts "Current version of IP is $version"
puts "======================================"

#set ipDefs [get_ip_upgrade_results [get_ips]]
# for {set x 0} {$x<[llength $ipDefs]} {incr x} {
#     set ipRoot [file rootname [lindex $ipDefs $x]]
#     puts
#     "Upgrade Log for $ipRoot"
#     set ipDir [get_property IP_DIR [get_ips $ipRoot]]
#     set ipLog [lindex $ipDefs $x]
#     set catLog [concat $ipDir/$ipLog]
#     # Check for file existence, and read file contents
#     if {[file isfile $catLog]} {
#         # Open the file for read, save the File Handle
#         set FH [open $catLog r]
#         #puts "Open $FH"
#         set content [read $FH]
#         foreach line [split $content \n] {
#             # The current line is saved inside $line variable
#             puts $line
#         }
#         close $FH
#         #puts "Close $FH"
#     }
# }
