# Source metadata
source ./tcl/metadata.tcl

# Open project
set ip_project [ open_project ${proj_dir}/${design}.xpr ]

#ipx::package_project
##set ip_core [ipx::current_core]
#ipx::check_integrity ${ip_core}

ipx::edit_ip_in_project -upgrade true -name ${design}_project  -directory ${proj_dir}

# Read source files from hdl directory
set v_src_files1 [glob ./hdl/*.v]
set sv_src_files [glob ./hdl/*.sv]
#set mem_src_files [glob ./hdl/*.mem]
read_verilog ${v_src_files1}
read_verilog -sv ${sv_src_files}
#read_mem ${mem_src_files}
update_compile_order -fileset sources_1


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

