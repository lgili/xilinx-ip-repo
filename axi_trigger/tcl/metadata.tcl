set design "axi_trigger"
set top "${design}_wrapper"
set proj_dir "./ip_proj"

set ip_properties [ list \
    vendor "gili.com" \
    library "AXI" \
    name ${design} \
    version "1.0" \
    taxonomy "/AXI_Application" \
    display_name "AXI Trigger" \
    description "Read data from adc and generate a trigger signal based on input value disviation" \
    vendor_display_name "Luiz Carlos Gili" \
    company_url "http://gili.com" \
    ]

set family_lifecycle { \
  artix7 Production \
  artix7l Production \
  kintex7 Production \
  kintex7l Production \
  kintexu Production \
  kintexuplus Production \
  virtex7 Production \
  virtexu Production \
  virtexuplus Production \
  zynq Production \
  zynquplus Production \
  aartix7 Production \
  azynq Production \
  qartix7 Production \
  qkintex7 Production \
  qkintex7l Production \
  qvirtex7 Production \
  qzynq Production \
}
