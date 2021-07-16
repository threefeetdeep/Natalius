`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//                          NATALIUS-II CPU TOP LEVEL
//////////////////////////////////////////////////////////////////////////////////

// include guard
`ifndef NATALIUS_PROCESSOR_V
`define NATALIUS_PROCESSOR_V

`define TESTBENCH   // comment out when not simulating...


// include sub-modules
`include "control_unit.v"
`include "data_path.v"
`include "instruction_memory.v"
`include "memram.v"

module natalius_processor(
    input clk,
    input rst,
    output [7:0] port_addr,
    output read_e,
    output write_e,
    input [7:0] data_in,
    output [7:0] data_out    
    );
    
    // override with path to your program code file from instantiating code at top level:
    parameter PATH_TO_PROG_CODE = "instructions.mem"; 


    // internal wire and reg
    wire zero, carry;
    wire insel;
    wire we;
    wire [2:0] raa;
    wire [2:0] rab;
    wire [2:0] wa;
    wire [2:0] opalu;
    wire [2:0] sh;
    wire selpc;
    wire ldpc;
    wire ldflag;
    wire [10:0] ninst_addr;
    wire selk;
    wire [7:0] KTE;
    wire [10:0] stack_addr;
    wire wr_en, rd_en;
    wire [7:0] imm;
    wire selimm;
    wire [15:0] instruction;
    wire [10:0] inst_addr;
    wire [10:0] ROM_data_addr;		// address in ROM to fetch data byte from

    // Instantiate CPU sub-modules
    control_unit the_control_unit (clk, rst, instruction, zero, carry, port_addr, write_e, read_e, insel, 
                                we, raa, rab, wa, opalu, sh, selpc, ldpc, ldflag, ninst_addr,
                                selk, KTE, stack_addr, wr_en, rd_en, imm, selimm);

    data_path the_data_path      (clk, rst, data_in, insel, we, raa, rab, wa ,opalu, sh, selpc, selk, 
                                ldpc, ldflag, wr_en, rd_en, ninst_addr, KTE, imm, selimm, 
                                data_out, inst_addr, stack_addr, zero, carry);

    instruction_memory #(.PROGRAM_CODE(PATH_TO_PROG_CODE)) the_ROM (clk,inst_addr,instruction);

endmodule



//////////////////////////////////////////////////////////////////////////////////
//                           TESTBENCH SIMULATION
//////////////////////////////////////////////////////////////////////////////////
// TO RUN TESTBENCH:
// 1. uncomment out the TESTBENCH define
// 2. iverilog -g2001 -o tb_natalius.out -s tb_natalius natalius_processor.v
// 3. vvp tb_natalius.out
// 4. gtkwave tb_natalius.vcd

`ifdef TESTBENCH 


module tb_natalius();
    // input as reg, outputs as wires
    reg sim_clk;
    reg rst;
    wire [7:0] port_addr;
    wire read_e;
    wire write_e;
    reg[7:0] data_in;
    wire [7:0] data_out;


    // simple test program to exercise all types of instructions
    parameter ROM_FILE = "./assembler/testbench.mem"; 
    // internal reg and wire

    // instantiate CPU MUT
    natalius_processor #(.PATH_TO_PROG_CODE(ROM_FILE)) processor (sim_clk, rst, port_addr, read_e, write_e, data_in, data_out);   

    // save simulation data
    initial begin
        $dumpfile("tb_natalius.vcd");
        $dumpvars(0,tb_natalius);
    end

    // simulation clock 20(ns) = 50MHz
    localparam CLK_PERIOD = 20;
    initial sim_clk = 0;
    always #(CLK_PERIOD / 2.0)
        sim_clk = ~sim_clk;

    // simulation terminate (adjust as needed; 3 clk periods per instruction
    initial #2000 $finish;  // 60+ instructions, roughly...

    // simulation test vectors
    initial begin
        // reset
        rst = 1;
        // release reset
        #100 rst = 0;
        // let the CPU run it's test program and observe!!!

        // simulate RAM retrieving the value 123:
        #20 data_in = 123;
        /// ...
        // then throw in a reset late on in the sim...
        # 1800 rst =1;
        
    end

endmodule

`endif // testbench

`endif // include guard