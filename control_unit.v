`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//		16.07.2021 Oli Bailey
//		* added zero and carry flag effect to the follwing instructions:
//		* adi, add, sub, oor, and, xor
//		* added load from ROM 'ldr' instruction to allow storing data in ROM
//
//////////////////////////////////////////////////////////////////////////////////
module control_unit(
    input clk,
    input rst,
    input [15:0] instruction,		// the latest instruction loaded from ROM to be decoded
    input zero,						// the current state of the zero flag
    input carry,					// the current state of the carry flag
    output reg [7:0] port_addr,		// the external memory address
    output reg write_e,				// write to external memory or I/O signal
    output reg read_e,				// read from external memory or I/O signal
    output reg insel,				// is the register file to have data from the shifter or the input mux?
    output reg we,					// write to register file enable
    output reg [2:0] raa,			// register A
    output reg [2:0] rab,			// register B
    output reg [2:0] wa,			// register to be written to for '... rA,rB' instructions
    output reg [2:0] opalu,			// which operation that the ALU should perform
    output reg [2:0] sh,			// which shift opertion that the shifter should perform
    output reg selpc,				// signal to load PC with next instruction address (otherwise increment it)
    output reg ldpc,				// signal to load new value to PC
    output reg ldflag,				// signal to transfer ALU Z/C outputs to the Z/C register
    output reg [10:0] naddress,		// next instruction address from jump or call instructions
    output reg selk,				// directs a literal to the data mux
    output reg [7:0] KTE,			// register to hold a literal value in an instruction
	 input [10:0] stack_addr,		// the current address at the top of the stack
	 output reg wr_en, rd_en,		// signals to push and pop an address to the stack
	 output reg [7:0] imm,			// immediate (literal) value for 'adi' add immediate instruction (NOTE: there is no 'subi')
	 output reg selimm   			// direct the 'add' instruction literal 'imm' to the data mux
    );


///////////////////////////////////////////////////////////////////////////////
//							INSTRUCTION OPCODES
///////////////////////////////////////////////////////////////////////////////
// (The following are all Instruction Decoder Mealy-type FSM states)
parameter fetch=	5'd0;		
parameter decode=	5'd1;
parameter ldi=		5'd2;		// load a register (r0..r7) with a literal (0x00..0xFF)
parameter ldm=		5'd3;		// load a register (r0..r7) from IO (0x20-0xFF) or RAM (0x00-0x1F)
parameter stm=		5'd4;		// store a register (r0..r7) to IO  (0x20-0xFF) or RAM (0x00-0x1F)
parameter cmp=		5'd5;		// compare one register to another (affects zero and carry)
parameter add=		5'd6;		// 'add rA,rB' : add register B to register A, and store in A.
parameter sub=		5'd7;		// 'sub rA,rB' : sub register B from register A, and store in A. 
parameter and_=		5'd8;		// 'and_ rA,N' : rA = rA & N 		NOTE: 'and' is a Verilog keyword hence 'and_'...
parameter oor=		5'd9;		// 'oor rA,rB' : rA = rA | N 		NOTE: 'or' is a Verilog keyword hence 'oor'...
parameter xor_=		5'd10;		// 'xor_ rA,N' : rA = rA | N 		NOTE: 'xor' is a Verilog keyword hence 'xor_'...
parameter jmp=		5'd11;      // 'jmp 0xhhhh' : jump (change PC) to 0xhhhh (in ROM range 0x0000-0x07FF)
parameter jpz=		5'd12;		// 'jpz 0xhhhh' : jump (change PC) to 0xhhhh (in ROM range 0x0000-0x07FF) if Z flag was set
parameter jnz=		5'd13;		// 'jnz 0xhhhh' : jump (change PC) to 0xhhhh (in ROM range 0x0000-0x07FF) if Z flag was not set
parameter jpc=		5'd14;		// 'jpc 0xhhhh' : jump (change PC) to 0xhhhh (in ROM range 0x0000-0x07FF) if C flag was set
parameter jnc=		5'd15;		// 'jpc 0xhhhh' : jump (change PC) to 0xhhhh (in ROM range 0x0000-0x07FF) if C flag was not set
parameter csr=		5'd16;		// 'csr 0xhhhh' : call subroutine - (push PC) jump to 0xhhhh. 'ret' will pop (restore) PC
parameter ret=		5'd17;		// return from subroutine (pop PC)
parameter adi=		5'd18;      // 'add rA,N' : rA = rA + N 	
parameter csz=		5'd19;		// 'csr 0xhhhh' : call subroutine - (push PC) jump to 0xhhhh, if Z flag was set
parameter cnz=		5'd20;		// 'cnz 0xhhhh' : call subroutine - (push PC) jump to 0xhhhh, if Z flag was not set
parameter csc=		5'd21;		// 'csc 0xhhhh' : call subroutine - (push PC) jump to 0xhhhh, if C flag was set
parameter cnc=		5'd22;		// 'cnc 0xhhhh' : call subroutine - (push PC) jump to 0xhhhh, if C flag was  not set
parameter sl0=		5'd23;		// 'sl0, rA'  	: rA = rA >> 1  (left filled with 0)
parameter sl1=		5'd24;		// 'sl1, rA'  	: rA = rA >> 1  (left filled with 1)
parameter sr0=		5'd25;		// 'sr0, rA'  	: rA = rA << 1  (right filled with 0)
parameter sr1=		5'd26;		// 'sr1, rA'  	: rA = rA << 1  (right filled with 1)
parameter rrl=		5'd27;		// 'rrl, rA'  	: rotate rA left one bit
parameter rrr=		5'd28;		// 'rrr, rA'  	: rotate rA right one bit
parameter not_=		5'd29;		// 'not_ rA'  : rA = ~rA			NOTE: 'not' is a Verilog keyword hence 'not_'...
parameter nop=		5'd30;		//  No Operation - waste 3 clock cycles
parameter ldr= 		5'd31;   	//  'ldr rA,0xhhhh' : loads register A with lower 8 bits of ROM content at location 0xhhhh



wire [4:0] opcode;
reg [4:0] state;

// Opcode is stored in the top 5 bits of each instruction
assign opcode=instruction[15:11];

// Mealy FSM (next) state logic:  'fetch --> decode --> execute' and repeat, 3 clk cycles total
always@(posedge clk or posedge rst)
	if (rst)
		state <= decode;
	else
		case (state)
			decode: case (opcode)  // 'execute' states
						2		: 	state <= ldi;
						3		:	state <= ldm;
						4		:	state <= stm; 
						5		:	state <= cmp;
						6		:	state <= add;
						7		:	state <= sub;
						8		:	state <= and_;
						9		:	state <= oor;
						10		:	state <= xor_;
						11		:	state <= jmp;
						12		:	state <= jpz;
						13		:	state <= jnz;
						14		:	state <= jpc;
						15		:	state <= jnc;
						16		:	state <= csr;
						17		:	state <= ret;
						18		:	state <= adi;
						19		:	state <= csz;
						20		:	state <= cnz;
						21		:	state <= csc;
						22		:	state <= cnc;
						23		:	state <= sl0;
						24		:	state <= sl1;
						25		:	state <= sr0;
						26		:	state <= sr1;
						27		:	state <= rrl;
						28		:	state <= rrr;
						29		:	state <= not_;
						31		:	state <= ldr;
						default	:	state <= nop;
					endcase
			
			ldi:	state <= fetch;
					
			ldm:	state <= fetch;
					
			stm:	state <= fetch;
					
			cmp:	state <= fetch;
					
			add:	state <= fetch;
					
			sub:	state <= fetch;
					
			and_:	state <= fetch;
					
			oor:	state <= fetch;
					
			xor_:	state <= fetch;
							
			jmp:	state <= fetch;
						
			jpz: 	state <= fetch;
			
			jnz: 	state <= fetch;
			
			jpc: 	state <= fetch;
			
			jnc: 	state <= fetch;
			
			csr: 	state <= fetch;
			
			ret: 	state <= fetch;
			
			adi:	state <= fetch;
			
			csz:	state <= fetch;
			
			cnz:	state <= fetch;
			
			csc:	state <= fetch;
			
			cnc:	state <= fetch;
			
			sl0:	state <= fetch;
			
			sl1:	state <= fetch;
			
			sr0:	state <= fetch;
			
			sr1:	state <= fetch;
			
			rrl:	state <= fetch;
			
			rrr:	state <= fetch;
			
			not_:	state <= fetch;
						
			nop: 	state <= fetch;

			ldr:	state <= fetch;

			fetch: state <= decode;
			endcase
	

// Mealy FSM output logic
always@(*)
	begin
		// assign by exception:
		port_addr <= 0;
		write_e <= 0;
		read_e <= 0;
		insel <= 0;
		we <= 0;
		raa <= 0;
		rab <= 0;
		wa <= 0;
		opalu <= 4;
		sh <= 4;
		selpc <= 0;
		ldpc <= 1;
		ldflag <= 0;
		naddress <= 0;
		selk <= 0;
		KTE <= 0;
		wr_en <= 0;
		rd_en <= 0;
		imm <= 0;
		selimm <= 0;
		
		case (state)
			fetch: ldpc  <=  0;
					
			decode:  begin
							ldpc  <=  0;
							if (opcode == stm)
								begin
									raa  <=  instruction[10:8];
									port_addr  <=  instruction[7:0];
								end
							else if (opcode == ldm)
								begin
									wa  <=  instruction[10:8];
									port_addr  <=  instruction[7:0];
								end
						    // prepare to read from ROM 0x07nn into register in 'wa'...
							else if (opcode == ldr)
								begin
									wa  <=  instruction[10:8]; // 'nn'
									naddress <= {3'h7, instruction[7:0]};
								end
							// return instruction, so prepare to pop from stack 
							else if (opcode == ret)
								begin
									rd_en <= 1;
								end
						end
				
			ldi:	begin
						selk  <=  1;
						KTE <= instruction[7:0];
						we <= 1;
						wa <= instruction[10:8];
					end
					
			ldm:	begin
						wa <= instruction[10:8];
						we <= 1;
						read_e <= 1;
						port_addr <= instruction[7:0];
					end

			ldr:	begin 
						wa <= instruction[10:8];
						we <= 1;
						// ???? Can this be done? Reading from ROM before PC is applied to
						// fetch the next instruction?	

					end
					
			stm:	begin
						raa <= instruction[10:8];
						write_e <= 1;
						port_addr <= instruction[7:0];
					end
					
			cmp:	begin
						ldflag <= 1;
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						opalu <= 6;
					end
					
			add:	begin
						ldflag <= 1;  
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 5;
						we <= 1;
					end
					
			sub:	begin
						ldflag <= 1;  
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 6;
						we <= 1;
					end
					
			and_:	begin
						ldflag <= 1; 
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 1;
						we <= 1;
					end
					
			oor:	begin
						ldflag <= 1;  
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 3;
						we <= 1;
					end
					
			xor_:	begin
						ldflag <= 1;  
						raa <= instruction[10:8];
						rab <= instruction[7:5];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 2;
						we <= 1;
					end

			// jumps to new ROM location - prepare to change PC to new address		
			jmp:	begin
						naddress <= instruction[10:0];
						selpc <= 1;
						ldpc <= 1;
					end
					
			jpz:		if (zero)
						begin
							naddress <= instruction[10:0];
							selpc <= 1;
							ldpc <= 1;
						end
										
			jnz:		if (!zero)
							begin
								naddress <= instruction[10:0];
								selpc <= 1;
								ldpc <= 1;
							end
						
					
			jpc:	if (carry)
							begin
								naddress <= instruction[10:0];
								selpc <= 1;
								ldpc <= 1;
							end
						
					
			jnc:	if (!carry)
							begin
								naddress <= instruction[10:0];
								selpc <= 1;
								ldpc <= 1;
							end
			// subroutine calls - prepare to push PC to stack and jump to new address				
			csr:	begin
						naddress <= instruction[10:0];
						selpc <= 1;
						ldpc <= 1;
						wr_en <= 1;
					end
			
			csz:	if (zero)
						begin
							naddress <= instruction[10:0];
							selpc <= 1;
							ldpc <= 1;
							wr_en <= 1;
						end
						
			cnz:	if (!zero)
						begin
							naddress <= instruction[10:0];
							selpc <= 1;
							ldpc <= 1;
							wr_en <= 1;
						end
					
			csc:	if (carry)
						begin
							naddress <= instruction[10:0];
							selpc <= 1;
							ldpc <= 1;
							wr_en <= 1;
						end
					
			cnc:	if (!carry)
						begin
							naddress <= instruction[10:0];
							selpc <= 1;
							ldpc <= 1;
							wr_en <= 1;
						end

			// return from subroutine - pop from stack to PC 		
			ret:	begin
						naddress <= stack_addr;
						selpc <= 1;
						ldpc <= 1;
					end

			// arithmetic and logic - prepare ALU or shifter unit for operation		
			adi:	begin
						ldflag <= 1;  
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						imm <= instruction[7:0];
						selimm <= 1;
						insel <= 1;
						opalu <= 5;
						we <= 1;
					end	
				
			
			sl0:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 0;
						we <= 1;
					end
					
			sl1:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 5;
						we <= 1;
					end
					
			sr0:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 2;
						we <= 1;
					end
					
			sr1:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 6;
						we <= 1;
					end	

			rrl:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 1;
						we <= 1;
					end						
					
			rrr:	begin	
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						sh <= 3;
						we <= 1;
					end
					
			not_:	begin
						raa <= instruction[10:8];
						wa <= instruction[10:8];
						insel <= 1;
						opalu <= 0;
						we <= 1;
					end

			nop:	opalu <= 4;
						
		endcase
	end
			

endmodule
