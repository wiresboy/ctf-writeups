`timescale 1ns / 1ps


module top_wrap( //wrapper using pin names
  input wire A13_PIO, //0 40
  input wire B17_PIO, //0 60
  input wire R0C31_TDCC0, //clk
  output wire A12_PIO,
  output wire R0C40_SIOLOGICA
);

	top top(.MIB_R0C60_PIOT0_JPADDIA_PIO(B17_PIO),  //input = reset
			.G_HPBX0000(R0C31_TDCC0),               //input = clk
			.MIB_R0C40_PIOT0_JPADDIB_PIO(A13_PIO),  //input
			.MIB_R0C40_PIOT0_JTXDATA0A_SIOLOGIC(A12_PIO) //output
			);
	
	assign R0C40_SIOLOGICA = A12_PIO;


endmodule

module top_tb();

	logic a13; //in
	logic b17;
	logic clk;
	logic a12; //out
	logic txd; //out
	
	logic dat;
	logic rst;
	
	logic [7:0] test_byte;
	logic [7:0] trans_buffer;
	

	top_wrap top_wrap(.A13_PIO(a13),
			.B17_PIO(b17),
			.R0C31_TDCC0(clk),
			.A12_PIO(a12),
			.R0C40_SIOLOGICA(txd)
	);
	
	always begin clk=~clk; #0.5; end
	
	assign a13 = dat; //This seems to be the right hookup
	assign b17 = rst;
	
	
	
	initial begin
	
		//force top_wrap.top.\ = ;
	
		//force top_wrap.top.\R2C35_PLC2_inst.sliceB_inst.ff_0.CE = 1; //Enables a 10-counter, but it seems like said counter has more bits?
		force top_wrap.top.\R4C37_PLC2_inst.sliceA_inst.ff_1.Q = 0;  //Doesn't do much on its own.
		
		force top_wrap.top.\R3C37_PLC2_inst.sliceC_inst.ff_0.Q = 1; //CE for output reg
		force top_wrap.top.\R3C37_PLC2_inst.sliceD_inst.genblk9.lut4_0.D = 1; // 8 parallel regs, maybe output buffer?
		force top_wrap.top.\R3C38_PLC2_inst.sliceA_inst.genblk9.lut4_0.D = 1;
		force top_wrap.top.\R3C37_PLC2_inst.sliceD_inst.genblk9.lut4_0.D = 1;

		force top_wrap.top.\R2C39_PLC2_inst.sliceD_inst.ff_0.CE = 1;

		test_byte = 0; //Initial test
		
		rst = 0;
		dat = 1;
		clk = 0;
		#200;
		rst = 1;
		#200;
		rst = 0;
		#1000;
		
		
		//Start tx
		repeat (258) begin //Cycle through all bytes, and then some
			trans_buffer = test_byte;
			
			//rst = 1; //For testing: Reset on each cycle?
			//#1000
			//rst = 0;
			//#100
			
			dat = 0; //start bit
			#100;
			repeat (8) begin //8x data bits
				dat = trans_buffer[0];
				#100
				trans_buffer = {1'b0, trans_buffer[7:1]};
			end
			dat = 1; //stop bit
			#300;
			
			test_byte = test_byte + 1; //Next byte
		end
		
		
		rst = 1; //Turn on reset line
		test_byte = 0;
		#100000 //and wait a while
		$finish;
	end
endmodule
