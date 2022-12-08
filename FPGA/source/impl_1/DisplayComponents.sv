/***************************************************************************************************************************/
/*											DISPLAYCOMPONENTS.SV														   */
/***************************************************************************************************************************/
//////////////////////////////////////////////////////////////////////
//						COLSHIFT	MODULE							//
//		Shifts the column data into ths shift registers 			//
//		when in the shift_col state. Enters reset_col state 		//
//		upon shifting all the data. Exits the reset_col state when	//
//		pwm_en is asserted.											//
//////////////////////////////////////////////////////////////////////
typedef enum logic [2:0] {reset_col, shift_col} ColState;
module ColShift(input logic clk,
				input logic reset,
				input logic col_cnt_en,
				input logic [63:0] r0_in,
				input logic [63:0] r1_in,
				input logic [63:0] g0_in,
				input logic [63:0] g1_in,
				input logic [63:0] b0_in,
				input logic [63:0] b1_in,					
				output logic r0_out,
				output logic r1_out,
				output logic g0_out,
				output logic g1_out,
				output logic b0_out,
				output logic b1_out,
				output logic col_cnt_overflow,
				output logic col_sck);
	ColState current_state, next_state;		//current and next state
	logic increment;						//increment: is only 1 when in the default_col state
	logic [5:0] count;						//keeps track of the column count
	Counter ColCounter(clk,reset,increment,count);	//counter module for column count
	
	//state register
	always_ff @(posedge clk) begin
		if(reset)begin
			current_state<=reset_col;
		end
		else current_state<=next_state;
	end
	
	//next state logic
	always_comb
		case(current_state)
			shift_col: 	if(col_cnt_overflow) next_state = reset_col;
						else next_state = shift_col;
			reset_col: 	if(col_cnt_en) next_state = shift_col;
						else next_state = reset_col;
			default: next_state = reset_col;
		endcase
	
	//output logic
	assign col_cnt_overflow = count==6'b111111;
	assign increment = current_state==shift_col;
	assign r0_out = r0_in[count];	//set the RGBs to the value in the index
	assign r1_out = r1_in[count];
	assign g0_out = g0_in[count];
	assign g1_out = g1_in[count];
	assign b0_out = b0_in[count];
	assign b1_out = b1_in[count];
	
	assign col_sck = (current_state==reset_col)?0:clk;
endmodule

/***************************************************************************************************************************/
/*													DISPLAYCOMPONENTS.SV												   */
/***************************************************************************************************************************/

//////////////////////////////////////////////////////////////////////
//						COMBCOLORMOD	MODULE						//
//		Shifts the column data into ths shift registers 			//
//		when in the shift_col state. Enters reset_col state 		//
//		upon shifting all the data. Exits the reset_col state when	//
//		pwm_en is asserted.											//
//////////////////////////////////////////////////////////////////////
module CombColorMod #(WIDTH=4) (input logic [WIDTH-1:0] pwm_cnt,
								input logic [WIDTH-1:0] r0_in [63:0],
								input logic [WIDTH-1:0] r1_in [63:0],
								input logic [WIDTH-1:0] g0_in [63:0],
								input logic [WIDTH-1:0] g1_in [63:0],
								input logic [WIDTH-1:0] b0_in [63:0],
								input logic [WIDTH-1:0] b1_in [63:0],
								output logic [63:0]r0_out,
								output logic [63:0]r1_out,
								output logic [63:0]g0_out,
								output logic [63:0]g1_out,
								output logic [63:0]b0_out,
								output logic [63:0]b1_out);
	//Every value in the rows gets assigned based on if its less than or equal to the count
	always_comb begin
		for (int i=0; i<64;i=i+1) begin
			r0_out[i] = ~(r0_in[i]<=pwm_cnt);
			r1_out[i] = ~(r1_in[i]<=pwm_cnt);
			g0_out[i] = ~(g0_in[i]<=pwm_cnt);
			g1_out[i] = ~(g1_in[i]<=pwm_cnt);
			b0_out[i] = ~(b0_in[i]<=pwm_cnt);
			b1_out[i] = ~(b1_in[i]<=pwm_cnt);
		end
	end
endmodule

//////////////////////////////////////////////////////////////////////
//						COLORMODFSM	MODULE						//										
//		Handles the PWM increments, setting the output	display		//									
//		address, latching the data, and asserting / deasserting		//									
//		blank.														//									
//////////////////////////////////////////////////////////////////////
typedef enum logic [9:0] {reset_mod, shift_mod, blank_mod, addr_set_mod, latch_mod, unblank_mod, wait_mod, cnt_inc_mod, check_cnt_mod, pwm_overflow_mod, increment_wait_mod, memory_wait_mod} ColorModState;
module ColorModFSM #(WIDTH=4)  (input logic clk,
								input logic reset,
								input logic col_cnt_overflow,
								input logic pwm_en,
								input logic [4:0] next_addr,
								input logic in_sck,
								output logic blank,
								output logic [WIDTH-1:0] pwm_cnt,
								output logic latch,
								output logic [4:0]current_addr,
								output logic [5:0]row_0_sel,
								output logic [5:0]row_1_sel,
								output logic pwm_overflow,
								output logic sck,
								output logic col_cnt_en);
	
	ColorModState current_state, next_state;	
	logic pwm_inc;
	Counter #(.WIDTH(WIDTH)) PWMCounter( clk, reset,pwm_inc,pwm_cnt);
							
	//state register
	always_ff @(posedge clk) begin
		if(reset)begin
			current_state<=reset_mod;
		end
		else current_state<=next_state;
	end
	
	//next state logic
	always_comb
		case(current_state)
			reset_mod: 		if(pwm_en) next_state = addr_set_mod;
							else next_state = reset_mod;
			//addr_set_mod: 	next_state = shift_mod;
			addr_set_mod: 	if(pwm_en) next_state = shift_mod;
							else next_state = memory_wait_mod;
			memory_wait_mod: if(pwm_en) next_state = shift_mod;
							 else next_state = memory_wait_mod;
			shift_mod: 		if(col_cnt_overflow)next_state = blank_mod;
							else next_state = shift_mod;
			blank_mod: 		next_state = latch_mod;
			latch_mod: 		next_state = unblank_mod;
			unblank_mod:	next_state = wait_mod;
			wait_mod: 		next_state = cnt_inc_mod; 
			
			cnt_inc_mod: 	next_state = check_cnt_mod;
			check_cnt_mod: 	if(pwm_cnt==0 ) next_state = pwm_overflow_mod;
							else next_state =shift_mod;										
			pwm_overflow_mod: next_state = increment_wait_mod;
			increment_wait_mod:  next_state = addr_set_mod;	
			
			

			default: 		next_state = reset_mod;
			//TODO: NEED ANOTHER WAIT SIGNAL TO ENSURE STUFF FOR WHEN WE'RE GONNA READ AND WRITE DATA
		endcase
	//output logic
	assign latch = current_state==latch_mod;
	//assign blank = ~(current_state==blank_mod|| current_state==addr_set_mod || current_state==latch_mod);
	assign blank = ~( current_state==unblank_mod || current_state==wait_mod);
	//assign blank = ~( current_state==unblank_mod );
	assign pwm_inc = (current_state ==cnt_inc_mod);
	assign row_0_sel = next_addr;
	assign row_1_sel = next_addr+32;
	//assign pwm_overflow = pwm_cnt==(1<<WIDTH)-1;
	assign sck = (~blank|| current_state==latch_mod || current_state == addr_set_mod)?0:in_sck;
	assign pwm_overflow = current_state==pwm_overflow_mod;
	
	assign col_cnt_en = current_state==shift_mod;
	
	//OverFlowDetector #(.WIDTH(WIDTH)) PWMOverflowDetect(clk, pwm_cnt, pwm_overflow);
	//output flop
	always_ff @(posedge clk) begin
		if(current_state==addr_set_mod)current_addr<=next_addr;
		else if(current_state == reset_mod)current_addr<=0;
	end


endmodule



//////////////////////////////////////////////////////////////////////
//							MAINDISPLAY FSM	MODULE					//
//		Coordinates all the timing for the display					//
//		components													//
//																	//
//////////////////////////////////////////////////////////////////////
typedef enum logic [4:0] {reset_main, pwm_en_main, pwm_main, increment_main, addr_set_wait_main,memread_main, mem_src_main, data_switch_main} MainDisplayState;
module MainDisplayFSM  (input logic clk,
						input logic reset,
						input logic pwm_overflow,
						input logic [4:0]current_addr,
						output logic pwm_en,
						output logic [4:0]next_addr,
						output logic read_en);
	
	MainDisplayState current_state, next_state;	
	logic row_inc;

	Counter #(.WIDTH(5)) RowCounter( clk, reset, row_inc, next_addr);

	//state register
	always_ff @(posedge clk) begin
		if(reset)begin
			current_state<=reset_main;
		end
		else current_state<=next_state;
	end
	
	//next state logic
	always_comb
		case (current_state)
			
			
			reset_main:			next_state = memread_main;
			memread_main:		next_state = pwm_main;
			pwm_main:			if(pwm_overflow) next_state = increment_main;
								else next_state = pwm_main;
			increment_main: 	next_state = addr_set_wait_main;
			
			addr_set_wait_main: if(current_addr==31) next_state = mem_src_main;
								else next_state=memread_main;
			
			
			mem_src_main: 		if(current_addr==0) next_state = data_switch_main;
								else next_state = memread_main;
			
			data_switch_main: next_state = memread_main;
			
			//wait_buffer_main:	next_state = memread_main;
			
			default: next_state = reset_main;
			
			
			
		endcase
	//output logic
	assign pwm_en = current_state==pwm_main;
	assign row_inc = current_state==increment_main;
	//assign read_en = current_state==memread_main;
	assign read_en = current_state==data_switch_main;
	
endmodule




//////////////////////////////////////////////////////////////////////
//							MAP TO RGB	MODULE						//
//						Does what it says.							//
//	Might be cool to have R,G,B change as function of amplitude		//
//	Or something													//
//////////////////////////////////////////////////////////////////////
module MapRGB #(WIDTH=4)   (input logic [5:0] row_0_sel,
							input logic [5:0] row_1_sel,
							input logic [63:0] row_0,
							input logic [63:0]row_1,
							output logic [WIDTH-1:0] r0[63:0],
							output logic [WIDTH-1:0] r1[63:0],
							output logic [WIDTH-1:0] g0[63:0],
							output logic [WIDTH-1:0] g1[63:0],
							output logic [WIDTH-1:0] b0[63:0],
							output logic [WIDTH-1:0] b1[63:0]);
	
	//adjusts the mapping based on amplitude?
	always_comb begin	
		for (int i=0; i<64;i=i+1) begin
			r0[i]= row_0[i]*row_0_sel;
			g0[i]= row_0[i]*15;
			b0[i]= row_0[i]*14;
			r1[i]= row_1[i]*row_1_sel;
			g1[i]= row_1[i]*15;
			b1[i]= row_1[i]*14;
			/*
			r0[i]= row_0[i]*row_0_sel;
			r1[i]= row_1[i]*row_1_sel;
			g0[i]= row_0[i]*row_0_sel;
			g1[i]= row_1[i]*(1<<(WIDTH)-1- row_1_sel/2);
			b0[i]= row_0[i]*(row_0_sel-1<<(WIDTH-1));
			b1[i]= row_1[i]*(row_1_sel-1<<(WIDTH-1));*/
		end
	end
endmodule

