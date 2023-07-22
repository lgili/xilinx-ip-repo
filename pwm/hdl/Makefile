



mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))
# VERILOG_INCLUDE_DIRS += \
# 	$(mkfile_dir)../../common/hdl/



VERILOG_SOURCES += $(mkfile_dir)pwm_wrapper.sv
VERILOG_SOURCES += $(mkfile_dir)clock_divider.sv
VERILOG_SOURCES += $(mkfile_dir)dff.v

# VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/fixedpoint.sv

