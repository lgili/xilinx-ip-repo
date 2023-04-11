# Source metadata
source ./tcl/metadata.tcl

# Create project 
set ip_project [ create_project -name ${design} -force -dir ${proj_dir} -ip ]
set_property top ${top} [current_fileset]
set_property source_mgmt_mode All ${ip_project}

# Read source files from hdl directory
set v_src_files [glob ./hdl/*.v]
# set sv_src_files [glob ./hdl/*.sv]
#set mem_src_files [glob ./hdl/*.mem]
read_verilog ${v_src_files}
# read_verilog -sv ${sv_src_files}
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
# ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
# set_property value 100000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]
ipx::add_port_map s00_axi_aclk [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property physical_name s00_axi_aclk [ipx::get_port_maps s00_axi_aclk -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property value s00_axi_aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
set_property value s00_axi [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]

# Set reset polarity
set aresetn_intf [ipx::get_bus_interfaces s00_axi_aresetn -of_objects ${ip_core}]
set aresetn_polarity [ipx::add_bus_parameter POLARITY $aresetn_intf]
set_property value ACTIVE_LOW ${aresetn_polarity}

ipx::add_bus_interface clk ${ip_core}
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
# ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
# set_property value 99999001 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]
ipx::add_port_map m00_axis_aclk [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property physical_name m00_axis_aclk [ipx::get_port_maps m00_axis_aclk -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property value m00_axis_aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
set_property value m00_axis [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]

# Set reset polarity
set aresetn_intf [ipx::get_bus_interfaces m00_axis_aresetn -of_objects ${ip_core}]
set aresetn_polarity [ipx::add_bus_parameter POLARITY $aresetn_intf]
set_property value ACTIVE_LOW ${aresetn_polarity}

# Save IP and close project
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}
close_project
# file delete -force ${proj_dir}