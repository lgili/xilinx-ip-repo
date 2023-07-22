import os
import sys

from hdlConvertorAst.language import Language
from hdlConvertor import HdlConvertor
from hdlConvertorAst.to.verilog.verilog2005 import ToVerilog2005

TEST_DIR = os.path.join(".")

filenames = [os.path.join(TEST_DIR, "opal_driver.vhd"), ]
include_dirs = ["work"]
c = HdlConvertor()
# note that there is also Language.VERILOG_2005, Language.SYSTEM_VERILOG_2017 and others
d = c.parse(filenames, Language.VHDL, include_dirs, hierarchyOnly=False, debug=True)


tv = ToVerilog2005(sys.stdout)
tv.visit_HdlContext(d)

print("fim")