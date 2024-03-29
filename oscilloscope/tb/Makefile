# Copyright (c) 2022 Luiz Carlos Gili
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

DUT      = oscilloscope
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
VERILOG_SOURCES += ../hdl/$(DUT).v

### adc files
VERILOG_SOURCES += ../hdl/adc/ad7276_if.v
VERILOG_SOURCES += ../hdl/adc/Data_transfer.sv
VERILOG_SOURCES += ../hdl/adc/Sampling_time.sv
VERILOG_SOURCES += ../hdl/adc/Sampling.sv
VERILOG_SOURCES += ../hdl/adc/Control.sv

VERILOG_SOURCES += ../hdl/async_uart.v

VERILOG_SOURCES += ../hdl/fifo/async_fifo.v
VERILOG_SOURCES += ../hdl/fifo/fifomem.v
VERILOG_SOURCES += ../hdl/fifo/rptr_empty.v
VERILOG_SOURCES += ../hdl/fifo/sync_r2w.v
VERILOG_SOURCES += ../hdl/fifo/sync_w2r.v
VERILOG_SOURCES += ../hdl/fifo/wptr_full.v

VERILOG_SOURCES += ../hdl/osc_s_axi.v
# VERILOG_SOURCES += ../hdl/async_receiver.v
# VERILOG_SOURCES += ../../hdl/moving_average_fir.v
# VERILOG_SOURCES += ../../hdl/zero_crossing_detector.v
# VERILOG_SOURCES += ../../hdl/passband_filter.v

# module parameters
export PARAM_DATA_WIDTH ?= 12
export PARAM_KEEP_ENABLE ?= $(shell expr $(PARAM_DATA_WIDTH) \> 8 )
export PARAM_KEEP_WIDTH ?= $(shell expr $(PARAM_DATA_WIDTH) / 8 )

ifeq ($(SIM), icarus)
	PLUSARGS += -fst

	# COMPILE_ARGS += -P $(TOPLEVEL).DATA_WIDTH=$(PARAM_DATA_WIDTH)
	# COMPILE_ARGS += -P $(TOPLEVEL).KEEP_ENABLE=$(PARAM_KEEP_ENABLE)
	# COMPILE_ARGS += -P $(TOPLEVEL).KEEP_WIDTH=$(PARAM_KEEP_WIDTH)
	

	ifeq ($(WAVES), 1)
		VERILOG_SOURCES += iverilog_dump.v
		COMPILE_ARGS += -s iverilog_dump
	endif
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += -Wno-SELRANGE -Wno-WIDTH

	COMPILE_ARGS += -GDATA_WIDTH=$(PARAM_DATA_WIDTH)
	COMPILE_ARGS += -GKEEP_ENABLE=$(PARAM_KEEP_ENABLE)
	COMPILE_ARGS += -GKEEP_WIDTH=$(PARAM_KEEP_WIDTH)

	ifeq ($(WAVES), 1)
		COMPILE_ARGS += --trace-fst
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

iverilog_dump.v:
	echo 'module iverilog_dump();' > $@
	echo 'initial begin' >> $@
	echo '    $$dumpfile("$(TOPLEVEL).fst");' >> $@
	echo '    $$dumpvars(0, $(TOPLEVEL));' >> $@
	echo 'end' >> $@
	echo 'endmodule' >> $@

clean::
	@rm -rf iverilog_dump.v
	@rm -rf dump.fst $(TOPLEVEL).fst
	@rm -rf results.xml
	@rm -rf -R __pycache__
