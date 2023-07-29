# Source metadata
source ./tcl/metadata.tcl

# Create project 
set ip_project [ create_project -name ${design} -force -dir ${proj_dir} -ip ]
set_property top ${top} [current_fileset]
set_property source_mgmt_mode All ${ip_project}

# Read source files from hdl directory
# set v_src_files [glob ./hdl/*.v]
set sv_src_files [glob ./hdl/*.sv]
set sv_src_files_1 [glob ./../common/hdl/*.sv]
# set sv_inc_files_1 [glob ./../common/hdl/*.vh]
#set mem_src_files [glob ./hdl/*.mem]
# read_verilog ${v_src_files}
read_verilog -sv ${sv_src_files}
read_verilog -sv ${sv_src_files_1}
# read_verilog -sv ${sv_inc_files_1}
#read_mem ${mem_src_files}
update_compile_order -fileset sources_1


# Package project and set properties
ipx::package_project
set ip_core [ipx::current_core]
set_property -dict ${ip_properties} ${ip_core}
set_property SUPPORTED_FAMILIES ${family_lifecycle} ${ip_core}

ipx::add_subcore gili.com:ip:common:1.0 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
update_compile_order -fileset sources_1


# Associate AXI/AXIS interfaces and reset with clock
ipx::add_bus_interface clk ${ip_core}
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
# ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
# set_property value 100000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK100MHz [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property physical_name CLK100MHz [ipx::get_port_maps CLK100MHz -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property value ARESETN [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
set_property value s_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]

# Set reset polarity
set aresetn_intf [ipx::get_bus_interfaces ARESETN -of_objects ${ip_core}]
set aresetn_polarity [ipx::add_bus_parameter POLARITY $aresetn_intf]
set_property value ACTIVE_LOW ${aresetn_polarity}

update_compile_order -fileset sources_1
ipx::add_bus_interface irq [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:interrupt_rtl:1.0 [ipx::get_bus_interfaces irq -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:interrupt:1.0 [ipx::get_bus_interfaces irq -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces irq -of_objects [ipx::current_core]]
ipx::add_port_map INTERRUPT [ipx::get_bus_interfaces irq -of_objects [ipx::current_core]]
set_property physical_name data_ready [ipx::get_port_maps INTERRUPT -of_objects [ipx::get_bus_interfaces irq -of_objects [ipx::current_core]]]


# Save IP and close project
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}
close_project
# file delete -force ${proj_dir}