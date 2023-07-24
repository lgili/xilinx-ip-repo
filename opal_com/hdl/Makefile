



mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))
VERILOG_INCLUDE_DIRS += \
	$(mkfile_dir)../../common/hdl/



VERILOG_SOURCES += $(mkfile_dir)opal_com_wrapper.sv
VERILOG_SOURCES += $(mkfile_dir)opal_com.sv
VERILOG_SOURCES += $(mkfile_dir)opal_com_s_axi.sv

# VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/fixedpoint.sv
# VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/vector_to_axis_tdest.sv
# VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/vector_to_axis.sv
# VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/axis_joiner_tdest.sv
