# Source metadata
source ./tcl/metadata.tcl

# Create project
set ip_project [ create_project -name ${design} -force -dir ${proj_dir} -ip ]
set_property top ${top} [current_fileset]
set_property source_mgmt_mode All ${ip_project}
# set_property source_mgmt_mode None [current_project]

# Read source files from hdl directory
set v_src_files1 [glob ./hdl/*.v]
set v_src_files2 [glob ./hdl/adc/*.v]
set v_src_files3 [glob ./hdl/fifo/*.v]
set sv_src_files [glob ./hdl/adc/*.sv]
#set mem_src_files [glob ./hdl/*.mem]
read_verilog ${v_src_files1}
read_verilog ${v_src_files2}
read_verilog ${v_src_files3}
read_verilog -sv ${sv_src_files}
#read_mem ${mem_src_files}
update_compile_order -fileset sources_1

# Package project and set properties
ipx::package_project
set ip_core [ipx::current_core]
set_property -dict ${ip_properties} ${ip_core}
set_property SUPPORTED_FAMILIES ${family_lifecycle} ${ip_core}

# Associate AXI/AXIS interfaces and reset with clock
ipx::add_bus_interface clk ${ip_core}
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
#ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
#set_property value 100000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK100MHz [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property physical_name CLK100MHz [ipx::get_port_maps CLK100MHz -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property value rst_n [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
set_property value s_axi: [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]

# set aclk_intf [ipx::get_bus_interfaces CLK100MHz -of_objects ${ip_core}]
# set aclk_assoc_intf [ipx::add_bus_parameter ASSOCIATED_BUSIF $aclk_intf]
# set_property value s_axi $aclk_assoc_intf
# set aclk_assoc_reset [ipx::add_bus_parameter ASSOCIATED_RESET $aclk_intf]
# set_property value rst_n $aclk_assoc_reset


# Set reset polarity
set aresetn_intf [ipx::get_bus_interfaces rst_n -of_objects ${ip_core}]
set aresetn_polarity [ipx::add_bus_parameter POLARITY $aresetn_intf]
set_property value ACTIVE_LOW ${aresetn_polarity}

# Save IP and close project
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}
close_project
# file delete -force ${proj_dir}