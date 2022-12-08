/***************************************************************************************************************************/
/*															MAIN.SV														   */
/***************************************************************************************************************************/



module top(		input logic r,
				input logic spi_sck,
				input logic sdi,
				input logic CE,
				
				output logic sdo,
				output logic r0_out,
				output logic r1_out,
				output logic g0_out,
				output logic g1_out,
				output logic b0_out,
				output logic b1_out,  
				output logic latch,
				output logic OE,
				output logic sck,
				output logic [4:0] addr);
	logic clk;
	logic reset;

	assign reset = ~r;
	
	
	SPIDisplayController #(.WIDTH(6)) DisplayControl(reset, spi_sck, sdi, CE, clk, sdo, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out, latch, OE, sck, addr);
	
	// Internal high-speed oscillator
	HSOSC #(.CLKHF_DIV(2'b01))
	hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));	
	

endmodule


//**********************************************************************************************************************************************************//
//																	DISPLAY CONTROL SECTION																	//
//**********************************************************************************************************************************************************//



module SPIDisplayController #(WIDTH=4) (
				input logic reset,
				input logic spi_sck,
				input logic sdi,
				input logic CE,
				input logic clk,
				output logic sdo,
				output logic r0_out,
				output logic r1_out,
				output logic g0_out,
				output logic g1_out,
				output logic b0_out,
				output logic b1_out,  
				output logic latch,
				output logic OE,
				output logic sck,
				output logic [4:0] addr);
	logic data_ready;
	
	logic [5:0] data_frame[63:0];
	logic [383:0] unpacked_frame;
	
	WireArrayToMatrix ArrayToMatrixModule(unpacked_frame, data_frame);
	
	
	SPIIn SpiModule (clk, spi_sck, sdi, CE, reset, sdo, unpacked_frame, data_ready);
	MemoryDisplay #(.WIDTH(WIDTH)) DisplayModule(clk, reset, data_frame, data_ready, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out, latch, OE, sck, addr );	
	
endmodule




//////////////////////////////////////////////////////////////////////
//						DISPLAYCONTROL	MODULE						//
//				Handles all the display stuff						//
//////////////////////////////////////////////////////////////////////
module DisplayController #(WIDTH=4)(input logic clk,
									input logic reset,
									input logic [63:0 ]row_0_in,
									input logic [63:0 ]row_1_in,
									output logic [4:0] current_addr,
									output logic blank,
									output logic latch,
									output logic r0_out,
									output logic r1_out,
									output logic g0_out,
									output logic g1_out,
									output logic b0_out,
									output logic b1_out,
									output logic out_clk,
									output logic read_en);
	//colshift
	logic pwm_en;
	logic [63:0] r0_cm_cs, r1_cm_cs,g0_cm_cs, g1_cm_cs, b0_cm_cs, b1_cm_cs;		
	logic col_cnt_overflow;	
	logic col_cnt_en;
	//combcolormod
    logic [WIDTH-1:0] pwm_cnt;
	logic [WIDTH-1:0] r0_map_cm [63:0];
	logic [WIDTH-1:0] r1_map_cm [63:0];
	logic [WIDTH-1:0] g0_map_cm [63:0];
	logic [WIDTH-1:0] g1_map_cm [63:0];
	logic [WIDTH-1:0] b0_map_cm [63:0];
	logic [WIDTH-1:0] b1_map_cm [63:0];
	logic col_sck;
	//maprgb
	logic[5:0] row_0_sel;
	logic[5:0] row_1_sel;	
	//ColorModFSM
	logic [4:0] next_addr;
	logic pwm_overflow;
	//////// MainDisplayFSM	////////
	MainDisplayFSM MainDisplayFSMModule(clk, reset, pwm_overflow,current_addr, pwm_en, next_addr,read_en);
	//////// ColorModFSM	////////
	ColorModFSM #(.WIDTH(WIDTH)) ColorModFSMModule(clk, reset, col_cnt_overflow, pwm_en, next_addr, col_sck,blank, pwm_cnt, latch, current_addr, row_0_sel, row_1_sel, pwm_overflow,out_clk,col_cnt_en);
	//////// MapRGB	////////
	MapRGB #(.WIDTH(WIDTH)) MapRGBModule(row_0_sel, row_1_sel, row_0_in, row_1_in, r0_map_cm, r1_map_cm, g0_map_cm, g1_map_cm, b0_map_cm, b1_map_cm);
	//////// CombColorMod	////////
	CombColorMod #(.WIDTH(WIDTH)) CombColorModulationModule(pwm_cnt, r0_map_cm, r1_map_cm, g0_map_cm, g1_map_cm, b0_map_cm, b1_map_cm, r0_cm_cs, r1_cm_cs, g0_cm_cs, g1_cm_cs, b0_cm_cs, b1_cm_cs);
	//////// ColShift	////////
	ColShift ColShiftModule (clk, reset, col_cnt_en,r0_cm_cs, r1_cm_cs, g0_cm_cs, g1_cm_cs, b0_cm_cs, b1_cm_cs, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out, col_cnt_overflow,col_sck);
	
endmodule


//////////////////////////////////////////////////////////////////////
//						MemoryDisplay	MODULE						//
//	Controls the Memory Display and double buffering				//
//////////////////////////////////////////////////////////////////////

module MemoryDisplay #(WIDTH=4)   (input logic clk,
								input logic reset,
								input logic  [5:0] data_frame [63:0],
								input logic data_ready,
								output logic r0_out,
								output logic r1_out,
								output logic g0_out,
								output logic g1_out,
								output logic b0_out,
								output logic b1_out,  
								output logic latch,
								output logic OE,
								output logic sck,
								output logic [4:0] addr);
	logic w_data_available;
	logic r_enable;
	logic get_buffer;
	
	logic [5:0] row_0_sel;
	logic [5:0] row_1_sel;
	
	assign row_0_sel = addr;
	assign row_1_sel = addr+32;
	
	logic [63:0] row_0_in;
	logic [63:0] row_1_in;
	//data ready is basically write enable (sort of)
	
	DisplayController #(.WIDTH(WIDTH)) DisplayControllerTest(clk, reset, row_0_in, row_1_in, addr, OE, latch, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out,sck,r_enable);	
	LevelMemControl MemController(clk, reset, data_ready, r_enable, data_frame, addr, row_0_in, row_1_in);
	

endmodule


//**********************************************************************************************************************************************************//
//																RAM AND DISPLAY COORDINATION																//
//**********************************************************************************************************************************************************//


module ToggleSynchronizer (input  logic clk_a,
						   input  logic clk_b,
						   input  logic pulse_in,
						   output logic pulse_out);
	logic qa;
	logic muxed;
	logic qb1;
	logic qb2;
	logic qb3;
	
	assign muxed = pulse_in ? ~qa: qa;
	
	//First Flop : a domain
	always_ff @(posedge clk_a)begin
		qa<= muxed;
	end
	//Second Flop: b domain
	always_ff @(posedge clk_b)begin
		qb1<= qa;
	end
	//Third Flop: b domain
	always_ff @(posedge clk_b)begin
		qb2<= qb1;
	end
	//Fourth Flop: b domain
	always_ff @(posedge clk_b)begin
		qb3<= qb2;
	end		
	
	assign pulse_out = qb3^qb2;
	
endmodule




//**********************************************************************************************************************************************************//
//																	OTHER CONTROL SECTION																	//
//**********************************************************************************************************************************************************//
//////////////////////////////////////////////////////////////////////
//							SPI MODULE								//
//////////////////////////////////////////////////////////////////////
module SPIIn #(WIDTH=512)(
			   input  logic clk,
			   input  logic sck, 
               input  logic sdi,
			   input  logic CE,
			   input  logic reset,
               output logic sdo,
			   output logic [383:0] data_frame,
			   output logic data_ready);			  
	logic [WIDTH-1:0] data_frame_buff;
	logic [WIDTH-1:0] data_frame_buff_stable;	
	logic [10:0] sck_count = 0;
	
	assign data_ready = ~CE;

	always_ff @(posedge sck)begin
		{data_frame_buff} = {data_frame_buff[WIDTH-2:0], sdi};
    end
    always_ff @(negedge sck) begin
        sdo <= data_frame_buff[WIDTH-1];
	end	
	/*always_ff @(posedge clk)begin
		if(data_ready) data_frame_buff_stable<=data_frame_buff;
	end*/

	always_ff @(negedge CE)begin
		data_frame_buff_stable<=data_frame_buff;
	end

	always_comb begin
		for ( int i = 64; i >0; i= i-1) begin
			 /*
			 data_frame[6*i-1] = data_frame_buff_stable[8*i-1];
			 data_frame[6*i-2] = data_frame_buff_stable[8*i-2];
			 data_frame[6*i-3] = data_frame_buff_stable[8*i-3];
			 data_frame[6*i-4] = data_frame_buff_stable[8*i-4];
			 data_frame[6*i-5] = data_frame_buff_stable[8*i-5];
			 data_frame[6*i-6] = data_frame_buff_stable[8*i-6];
			 */
			 
			 data_frame[6*i-1] = data_frame_buff_stable[8*i-3];
			 data_frame[6*i-2] = data_frame_buff_stable[8*i-4];
			 data_frame[6*i-3] = data_frame_buff_stable[8*i-5];
			 data_frame[6*i-4] = data_frame_buff_stable[8*i-6];
			 data_frame[6*i-5] = data_frame_buff_stable[8*i-7];
			 data_frame[6*i-6] = data_frame_buff_stable[8*i-8];
		end
	end
endmodule

/*module SPIIn #(WIDTH=512)(
			   input  logic clk,
			   input  logic sck, 
               input  logic sdi,
			   input  logic CE,
			   input  logic reset,
               output logic sdo,
			   output logic [383:0] data_frame,
			   output logic data_ready);			  
	logic [WIDTH-1:0] data_frame_buff;
	logic [WIDTH-1:0] data_frame_buff_stable;	
	logic [10:0] sck_count = 0;
	
	assign data_ready = ~CE;

	always_ff @(posedge sck)begin
		{data_frame_buff} = {data_frame_buff[WIDTH-2:0], sdi};
    end
    always_ff @(negedge sck) begin
        sdo <= data_frame_buff[WIDTH-1];
	end	
	always_ff @(posedge clk)begin
		if(data_ready) data_frame_buff_stable<=data_frame_buff;
	end
	//always_ff @(negedge CE)begin
		//data_frame_buff_stable<=data_frame_buff;
	//end

	always_comb begin
		for ( int i = 64; i >0; i= i-1) begin
			 //data_frame [6*i-1: 6*(i-1) ] = data_frame_buff_stable [8*i-1: 6*(i-1)];
			 data_frame[6*i-1] = data_frame_buff_stable[8*i-1];
			 data_frame[6*i-2] = data_frame_buff_stable[8*i-2];
			 data_frame[6*i-3] = data_frame_buff_stable[8*i-3];
			 data_frame[6*i-4] = data_frame_buff_stable[8*i-4];
			 data_frame[6*i-5] = data_frame_buff_stable[8*i-5];
			 data_frame[6*i-6] = data_frame_buff_stable[8*i-6];
		end
	end
endmodule*/





//////////////////////////////////////////////////////////////////////
//				Wire Array to Matrix								//
//		Should synthesize to a bunch of wires						//
//////////////////////////////////////////////////////////////////////

module WireArrayToMatrix #(WIDTH=64, DEPTH=6)  (input logic [WIDTH*DEPTH-1:0]array_in,
												output logic [DEPTH-1:0] matrix_out [WIDTH-1:0]);
	genvar i;
	for ( i = WIDTH; i>0; i=i-1) begin
		assign matrix_out [i-1] = array_in [(DEPTH*i-1): DEPTH*(i-1)];
	end
	
endmodule






//**********************************************************************************************************************************************************//
//																	COUNTERS AND CLOCKS																		//
//**********************************************************************************************************************************************************//


//////////////////////////////////////////////////////////////////////
//						COUNTER MODULE								//
//				Counts up and outputs the current count				//
//				Allows for a variable increment	(0 or 1)			//
//////////////////////////////////////////////////////////////////////
module Counter #(WIDTH=6)(	input logic clk, reset,
							input logic increment,
							output logic [WIDTH-1:0] out_count);


	logic [WIDTH-1:0] counter = 0;
	always_ff @(posedge clk)
		begin
			if(reset) counter<=0;
			else counter <= counter + increment;
		end	
	assign out_count = counter;
endmodule




//////////////////////////////////////////////////////////////////////
//						FIXED COUNTER MODULE						//
//			Counts up and outputs an overflow signal				//
//////////////////////////////////////////////////////////////////////
module FixedCounter #(WIDTH=6)(	input logic clk, reset,
								output logic [WIDTH-1:0] out_count);
	logic [WIDTH-1:0] counter = 0;
	always_ff @(posedge clk)
		begin
			if(reset) counter<=0;
			else counter <= counter + 1;
		end	
	assign overflow = counter==(1<<WIDTH)-1;
	assign out_count = counter;
endmodule

//////////////////////////////////////////////////////////////////////
//						INCREMENTER MODULE							//
//			Counts by a set increment and overflows					//
//////////////////////////////////////////////////////////////////////
module Incrementer #(WIDTH=25, INCREMENT=783)(	input logic clk_SwitchingSpeed,
												output logic sClk_SwitchingSpeed);
	logic [WIDTH-1:0] counter = 0;
	//Divides the clock by 2^WIDTH-1 and adds by INCREMENT. 
	always_ff @(posedge clk_SwitchingSpeed)
		begin
			counter <= counter + INCREMENT;
		end	
	//assigns the led to the counter
	assign sClk_SwitchingSpeed = counter[WIDTH-1];
endmodule


//////////////////////////////////////////////////////////////////////
//						ROWCLK MODULE								//
//			Generates the clock for the row	module					//
//////////////////////////////////////////////////////////////////////
module RowClk (	input logic clk,
				input logic reset,
				output logic row_clk);
	logic [4:0] clk_count;
	always_ff @(posedge clk)
	begin
		if (reset)
			clk_count<=0;
		else begin
			clk_count<=clk_count+1;
			row_clk<= clk_count[4];
			//row_clk<= (clk_count==69);
		end
	end
endmodule

