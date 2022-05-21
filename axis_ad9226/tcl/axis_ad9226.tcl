# Source metadata
source ./tcl/metadata.tcl

# Create project 
set ip_project [ create_project -name ${design} -force -dir ${proj_dir} -ip ]
set_property top ${top} [current_fileset]
set_property source_mgmt_mode All ${ip_project}

# Read source files from hdl directory
set v_src_files [glob ./hdl/*.v]
set sv_src_files [glob ./hdl/*.sv]
#set mem_src_files [glob ./hdl/*.mem]
read_verilog ${v_src_files}
read_verilog -sv ${sv_src_files}
#read_mem ${mem_src_files}
update_compile_order -fileset sources_1

#read_ip ./src/clk_wiz_0/clk_wiz_0.xci 
#set v_src_files [glob ./src/clk_wiz_0/*.v ]
#read_verilog ${v_src_files}
#update_compile_order -fileset sources_1

# Package project and set properties
ipx::package_project
set ip_core [ipx::current_core]
set_property -dict ${ip_properties} ${ip_core}
set_property SUPPORTED_FAMILIES ${family_lifecycle} ${ip_core}


foreach interface_name [list adc_1 adc_2 adc_3 adc_4] data_name [list s1_ad9226_data s2_ad9226_data s3_ad9226_data s4_ad9226_data] clk_name [list s1_ad9226_clk s2_ad9226_clk s3_ad9226_clk s4_ad9226_clk] \
 otr_name [list s1_otr s2_otr s3_otr s4_otr] enable_name [list ADC1_ENABLE ADC2_ENABLE ADC3_ENABLE ADC4_ENABLE] enable_debug_name [list button posTrigger state eoc] {

    ipx::add_bus_interface $interface_name ${ip_core}
    set_property abstraction_type_vlnv gili.com:user:ad9226_rtl:1.0 [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    set_property bus_type_vlnv gili.com:user:ad9226:1.0 [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    ipx::add_port_map data [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    set_property physical_name $data_name [ipx::get_port_maps data -of_objects [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]]
    ipx::add_port_map clk [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    set_property physical_name $clk_name [ipx::get_port_maps clk -of_objects [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]]
    ipx::add_port_map otr [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    set_property physical_name $otr_name [ipx::get_port_maps otr -of_objects [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]]
    #enable
    set enName ${enable_name}=true
    set_property enablement_dependency $enName [ipx::get_bus_interfaces $interface_name -of_objects ${ip_core}]
    set_property enablement_resolve_type dependent [ipx::get_ports $clk_name -of_objects ${ip_core}]
    set_property driver_value 0 [ipx::get_ports $clk_name -of_objects ${ip_core}]
    set_property enablement_dependency $enName [ipx::get_ports $clk_name -of_objects ${ip_core}]

    # gui
    set_property widget {checkBox} [ipgui::get_guiparamspec -name "$enable_name" -component ${ip_core} ]
    set_property value true [ipx::get_user_parameters $enable_name -of_objects ${ip_core}]
    set_property value true [ipx::get_hdl_parameters $enable_name -of_objects ${ip_core}]
    set_property value_format bool [ipx::get_user_parameters $enable_name -of_objects ${ip_core}]
    set_property value_format bool [ipx::get_hdl_parameters $enable_name -of_objects ${ip_core}]

}

foreach debug_enable [list button  debugPin] {
    set_property enablement_resolve_type dependent [ipx::get_ports $debug_enable -of_objects [ipx::current_core]]
    set_property driver_value 0 [ipx::get_ports $debug_enable -of_objects [ipx::current_core]]
    set_property enablement_dependency spirit:decode(id('MODELPARAM_VALUE.DEBUG_PORTS_ENABLE'))=true [ipx::get_ports $debug_enable -of_objects [ipx::current_core]]
}


ipx::add_bus_interface clk ${ip_core}
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
#ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
#set_property value 100000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property physical_name clk_100m [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk -of_objects ${ip_core}]
set_property value aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]
set_property value s_axi:s_axis:m_axis [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk -of_objects ${ip_core}]]

ipx::add_bus_interface clk_adc [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
set_property value 25000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
set_property physical_name clk_adc [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
ipx::add_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]
#set_property value aresetn [ipx::get_bus_parameters ASSOCIATED_RESET -of_objects [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]]
#set_property value m_axis [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk_adc -of_objects [ipx::current_core]]]


set_property range 4096 [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi -of_objects [ipx::current_core]]]
set_property range_dependency {pow(2,(spirit:decode(id('MODELPARAM_VALUE.AXI_ADDR_WIDTH')) - 1) + 1)} [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi -of_objects [ipx::current_core]]]


# Associate AXI/AXIS interfaces and reset with clock
#set aclk_intf [ipx::get_bus_interfaces clk_100m -of_objects ${ip_core}]
#set aclk_assoc_intf [ipx::add_bus_parameter ASSOCIATED_BUSIF $aclk_intf]
#set_property value s_axi:s_axis:m_axis $aclk_assoc_intf
#set aclk_assoc_reset [ipx::add_bus_parameter ASSOCIATED_RESET $aclk_intf]
#set_property value aresetn $aclk_assoc_reset


# Set reset polarity
set aresetn_intf [ipx::get_bus_interfaces aresetn -of_objects ${ip_core}]
set aresetn_polarity [ipx::add_bus_parameter POLARITY $aresetn_intf]
set_property value ACTIVE_LOW ${aresetn_polarity}


ipgui::move_param -component ${ip_core} -order 0 [ipgui::get_guiparamspec -name "ADC_DATA_WIDTH" -component ${ip_core}] -parent [ipgui::get_pagespec -name "Page 0" -component ${ip_core}]
ipgui::move_param -component ${ip_core} -order 1 [ipgui::get_guiparamspec -name "AXIS_DATA_WIDTH" -component ${ip_core}] -parent [ipgui::get_pagespec -name "Page 0" -component ${ip_core}]
ipgui::move_param -component ${ip_core} -order 2 [ipgui::get_guiparamspec -name "AXI_LITE_DATA_WIDTH" -component ${ip_core}] -parent [ipgui::get_pagespec -name "Page 0" -component ${ip_core}]
ipgui::remove_param -component ${ip_core} [ipgui::get_guiparamspec -name "C_M_AXIS_START_COUNT" -component ${ip_core}]
ipgui::remove_param -component ${ip_core} [ipgui::get_guiparamspec -name "AXI_ADDR_WIDTH" -component ${ip_core}]
set_property widget {checkBox} [ipgui::get_guiparamspec -name "DEBUG_PORTS_ENABLE" -component ${ip_core} ]
set_property value false [ipx::get_user_parameters DEBUG_PORTS_ENABLE -of_objects ${ip_core}]
set_property value false [ipx::get_hdl_parameters DEBUG_PORTS_ENABLE -of_objects ${ip_core}]
set_property value_format bool [ipx::get_user_parameters DEBUG_PORTS_ENABLE -of_objects ${ip_core}]
set_property value_format bool [ipx::get_hdl_parameters DEBUG_PORTS_ENABLE -of_objects ${ip_core}]

# Save IP and close project
ipx::check_integrity ${ip_core}
ipx::save_core ${ip_core}
close_project
#file delete -force ${proj_dir}
