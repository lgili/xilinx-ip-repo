



mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))
VERILOG_INCLUDE_DIRS += \
	$(mkfile_dir)../../common/hdl/



VERILOG_SOURCES += $(mkfile_dir)ad7276_wrapper.sv
VERILOG_SOURCES += $(mkfile_dir)adc_7276.v
VERILOG_SOURCES += $(mkfile_dir)ad7276_if.v
VERILOG_SOURCES += $(mkfile_dir)reset_gen.sv
VERILOG_SOURCES += $(mkfile_dir)ad7276_v1_s_axi.sv
VERILOG_SOURCES += $(mkfile_dir)clock_divider.sv 
VERILOG_SOURCES += $(mkfile_dir)dff.v 
VERILOG_SOURCES += $(mkfile_dir)ad7276_m_axis.v 
VERILOG_SOURCES += $(mkfile_dir)trigger_acq.sv 

VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/fixedpoint.sv
VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/vector_to_axis_tdest.sv
VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/vector_to_axis.sv
VERILOG_SOURCES += $(mkfile_dir)../../common/hdl/axis_joiner_tdest.sv
