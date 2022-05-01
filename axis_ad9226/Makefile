SCRIPT = $(shell basename `pwd`)

all: ip

ip: component.xml

component.xml:
	vivado -mode batch -source tcl/$(SCRIPT).tcl

rebuild:
	vivado -mode batch -source tcl/$(SCRIPT)_update.tcl

clean:
	rm -rf ip_*  vivado*.* *.xml xgui/ .Xil* *.*~ webtalk*
