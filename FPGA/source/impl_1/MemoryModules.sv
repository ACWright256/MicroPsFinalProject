
//**********************************************************************************************************************************************************//
//																 Memory related modules																//
//**********************************************************************************************************************************************************//







//////////////////////////////////////////////////////////////////////
//					ConvertToCoord MODULE							//
//	Takes a 6 bit depth vector and an address. The module			//
//	assigns the row pixels as 1s or 0s, depending on if the 		//													
//	6 bit depth value is equal to the row offset.					//
//																	//
//////////////////////////////////////////////////////////////////////
module RowsConvertToCoord  (input logic[5:0] level_dat[63:0],
							input logic [4:0] addr ,
							output logic [63:0] row_0,
							output logic [63:0] row_1);
		logic [5:0] row_0_sel;
		logic [5:0] row_1_sel;
		assign row_0_sel = addr;
		assign row_1_sel = addr+32;
		always_comb begin
			for(int i = 0; i< 64; i=i+1) begin
				row_0[i] = (level_dat[i]==row_0_sel);
				row_1[i] = (level_dat[i]==row_1_sel);
			end
		end
	
endmodule

//////////////////////////////////////////////////////////////////////
//					LevelMemControl MODULE							//
//	Saves the data from SPI and stores it for later use				//
//																	//
//////////////////////////////////////////////////////////////////////
module LevelMemControl (input logic clk,
						input logic reset,
						input logic w_enable,
						input logic r_enable,
						input logic [5:0] y_in [63:0],
						input logic [4:0] addr ,
						output logic [63:0] row_0,
						output logic [63:0] row_1);
	
	logic [5:0] data_stored [63:0];
	RowsConvertToCoord CoordConversion(data_stored, addr, row_0, row_1);
	
	//update the stored data when 
	always_ff @(posedge clk) begin 
		if(reset) data_stored <= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
		else if(w_enable && r_enable) data_stored <= y_in;
	end

	
endmodule







