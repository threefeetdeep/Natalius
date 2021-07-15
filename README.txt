CHANGES TO THE OPENCORES VERSION OF "NATALIUS":
-----------------------------------------------

* Changed print statements to print() in assembler.py to make it "Python3" compatible
* Changed Xilinx RAM_STYLE declarations to Altera/Intel style e.g. "(* ramstyle = "M144K" *)"
 (see https://www.intel.com/content/www/us/en/programmable/quartushelp/17.0/hdl/vlog/vlog_file_dir_ram.htm )
* Added includes and include guards to the processor files, so you only need to 
  include the top level in your porject, i.e.:

`include "CPU\Natalius\natalius_processor.v"

*