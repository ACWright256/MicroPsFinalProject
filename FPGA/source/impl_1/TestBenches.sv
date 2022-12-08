//******************************************************************//
//						Project Test Benches 						//
//******************************************************************//


//////////////////////////////////////////////////////////////////////
//							SPI Display TESTBENCH							//
//////////////////////////////////////////////////////////////////////
module SPIDisplay_tb();
	
	
	logic spi_sck;
	logic sdi;
	logic CE;
	logic sdo;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;  
	logic latch;
	logic OE;
	logic sck;
	logic [4:0] addr;
	logic clk;
	logic reset;
	

	//DUT
	SPIDisplayController DisplayControl(reset, spi_sck, sdi, CE, clk, sdo, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out, latch, OE, sck, addr);
	
	logic [10:0] i;
	Clk TestClk(clk);
	logic [511:0] return_msg, in_data;

    initial begin
      i = 0;
	  CE = 1;
	  reset = 1;
    end

    initial begin   
        in_data    <= 512'h0004080C1014181C2024282C3034383C4044484C5054585C6064686C7074787C8084888C9094989CA0A4A8ACB0B4B8BCC0C4C8CCD0D4D8DCE0E4E8ECF0F4F8FC;
        //in_data      <= 512'hFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFC;
    end

    // shift in test vectors, wait until done, and shift out result
    always @(posedge clk) begin
	
	  if(i==1) reset<=0;
      if (i == 512) 
		  begin
			  //return_msg[511] = sdo;
			CE = 1'b0;
		  end
      if (i<512) begin
        #1; sdi = in_data[511-i];
        #1; spi_sck = 1; #5; spi_sck = 0;
		return_msg[512-i] = sdo;
        i = i + 1;
      end 
	  

    end
	
	
	
endmodule;






//////////////////////////////////////////////////////////////////////
//							SPI TESTBENCH							//
//////////////////////////////////////////////////////////////////////
module SPI_tb();
	
	
	logic reset;
	assign reset = 0;
    logic clk, data_ready, CE, sck, sdi, sdo;
    logic [383:0] data_frame; 
	
	logic [511:0] return_msg, in_data;
	
	
	
    logic [10:0] i;
    // Added delay
    logic delay;
    
    // device under test
	SPIIn DUT(clk, sck, sdi, CE, reset, sdo, data_frame, data_ready);
    
    // test case
    initial begin   
        //in_data    <= 512'h0C1C2C3C4C5C6C7C8C9CACBCCCDCECFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFC0C1C2C3C4C5C6C7C8C9CACBCCCDCECFC;
        in_data      <= 512'hFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFCFC;
    end
    
    // generate clock and load signals
    initial 
        forever begin
            clk = 1'b0; #5;
            clk = 1'b1; #5;
        end
        
    initial begin
      i = 0;
	  CE = 1;
    end

    // shift in test vectors, wait until done, and shift out result
    always @(posedge clk) begin
      if (i == 512) 
		  begin
			  //return_msg[511] = sdo;
			CE = 1'b0;
		  end
      if (i<512) begin
        #1; sdi = in_data[511-i];
        #1; sck = 1; #5; sck = 0;
		return_msg[512-i] = sdo;
        i = i + 1;
      end 
	  /*else if(i<1024)begin
		 
		#1; sdi = in_data[511-i];
		
        #1; sck = 1; #5; sck = 0;
		return_msg[512-(i-512)] = sdo;
        i = i + 1;
	  end*/
    end
    
endmodule




module IntegratedEBR_tb();
	parameter COLORWID=4;
	logic clk;
	logic reset;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic OE;
	logic sck;
	logic [4:0] addr;
	
	initial begin
		#5;
		reset <=1;
		#10;
		reset<=0;
	end
	
	Clk TestClk(clk);
	TESTEBRDisplay #(.WIDTH(COLORWID))   DUT(clk, reset,r0_out, r1_out,g0_out,g1_out, b0_out,b1_out, latch,OE, sck,addr);
	
	
endmodule




//////////////////////////////////////////////////////////////////////
//					EBRController TESTBENCH							//
//////////////////////////////////////////////////////////////////////

module EBRController_tb();
	logic clk;
	logic reset;
	logic w_enable;
	logic r_enable;
	logic get_buffer;
	logic [5:0] y_in [63:0];
	logic [5:0] row_0_sel;
	logic [5:0] row_1_sel;
	logic [63:0] row_0;
	logic [63:0]row_1;
	Clk TestClk(clk);
		
	initial begin
		#5;
		reset<=1'b0;		//set reset to 0
		w_enable<=1'b0;		//set w_enable to 0
		r_enable<=1'b0;		//set r_enable to 0
		get_buffer<=1'b0;	//set get_buffer to 0
		$readmemb("EBR.tv",y_in);
		//y_in<= '{default:5'b00001};		//set y_in to all 1's
		row_0_sel<=0;		//set row_0_sel to 0
		row_1_sel<=32;		//set row_1_sel to 0
		#10;
		w_enable <=1;
		#10;
		w_enable<=0;
		#10;
		#10;
		get_buffer<=1'b1;	
		#10;
		get_buffer<=1'b0;
		r_enable<=1;
		#10;



		//#10;
		
		

	end
	
	//the DUT
	EBRController DUT(clk,reset,w_enable,r_enable,get_buffer, y_in,row_0_sel,row_1_sel,row_0,row_1);
	
	

	
	//main test loop
	always @(posedge clk) begin
		//increment

		if (row_0_sel==10)begin
			r_enable<=0;
			$readmemb("EBR1.tv",y_in);
			w_enable<=1;
			#10;
			w_enable<=0;
			#10;
			get_buffer<=1'b1;	
			#10;
			get_buffer<=1'b0;
			#10;
			r_enable<=1;
		end
		
		row_0_sel = row_0_sel+1;
		row_1_sel = row_1_sel+1;
	end
		
endmodule

//////////////////////////////////////////////////////////////////////
//					EBRWriteControl TESTBENCH						//
//////////////////////////////////////////////////////////////////////
module EBRWriteControl_tb();
	logic clk;
	logic reset;
	logic w_en;
	logic get_buffer;
	logic[5:0] y_in[63:0];
	logic [63:0] out_write_buffer [63:0];
	Clk TestClk(clk);


	
	initial begin
		y_in<= {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63};
		get_buffer<=0;
		#5;
		reset<=1;
		#10;
		reset<=0;
		#10;
		w_en<=1;
		#10;
		w_en<=0;
		get_buffer<=1;
		#10;
		#10;
		#10;
		#10;
		#10;
		#10;
		y_in<= {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
		#10;
		w_en<=1;
		#10;
		w_en<=0;
	end
	
	
	//DUT
	EBRWriteControl DUT (clk, reset, w_en, get_buffer, y_in, out_write_buffer);
	
	
	
endmodule



//////////////////////////////////////////////////////////////////////
//					EBRReadControl TESTBENCH						//
//////////////////////////////////////////////////////////////////////
module EBRReadControl_tb();
	logic clk;
	logic reset;
	logic r_en;
	logic get_buffer;
	logic [5:0] row_0_sel;
	logic [5:0] row_1_sel;
	logic [63:0] write_buffer [63:0];
	logic [63:0] row_0;
	logic [63:0]row_1;

	Clk TestClk(clk);

	//DUT
	EBRReadControl DUT(clk, reset, r_en, get_buffer, row_0_sel, row_1_sel, write_buffer, row_0, row_1);

endmodule



//////////////////////////////////////////////////////////////////////
//							ColShift TESTBENCH						//
//////////////////////////////////////////////////////////////////////


module MainDisplayFSM_tb();
	
	
	logic clk;
	logic reset;
	logic pwm_overflow;
	logic pwm_en;
	logic [4:0]current_addr;
	logic [4:0]next_addr;
	Clk TestClk(clk);
	
	
	
	
	initial begin
		#5;
		reset<=1'b1;
		#10;
		reset<=1'b0;
		#10;
		#10;
		#10;
		#10;
		#10;
		pwm_overflow<=1;
		#10;
		pwm_overflow<=0;
	end
	
	
	//The DUT
	MainDisplayFSM DUT(clk,reset, pwm_overflow, current_addr, pwm_en, next_addr);
	
	
endmodule









//////////////////////////////////////////////////////////////////////
//							ColShift TESTBENCH						//
//////////////////////////////////////////////////////////////////////
module ColShift_tb();
	logic clk;
	logic reset;
	logic pwm_en;
	logic col_cnt_overflow;
	logic [63:0] r0_in;
	logic [63:0] r1_in;
	logic [63:0] g0_in;
	logic [63:0] g1_in;
	logic [63:0] b0_in;
	logic [63:0] b1_in;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic col_sck;
	logic[63:0] tv[5:0];
			   
	//initialization
	initial begin
		reset<=1'b0;			//set reset to 0
		pwm_en<=1'b0;		//set data ready to false
		$readmemb("ColSelect.tv",tv);	//load test vectors
		assign r0_in = tv[0];	//set test vectors to channels
		assign g0_in = tv[1];
		assign b0_in = tv[2];
		assign r1_in = tv[3];
		assign g1_in = tv[4];
		assign b1_in = tv[5];
	end
	
	Clk TestClk(clk);
	//the DUT
	ColShift DUT(clk,reset,pwm_en,r0_in,r1_in,g0_in,g1_in,b0_in,b1_in,r0_out,r1_out,g0_out,g1_out,b0_out,b1_out,col_cnt_overflow,col_sck);
		
	initial begin
		#5;
		reset<=1'b1;
		#10;
		reset<=1'b0;
		pwm_en<=1;
		#10;
		pwm_en<=0;
	end
	//main loop
	always @(posedge clk) begin
		
	end
endmodule


//////////////////////////////////////////////////////////////////////
//							ColorModFSM TESTBENCH					//
//////////////////////////////////////////////////////////////////////
module ColorModFSM_tb();
	parameter COLORWID = 4;
    logic clk;
	logic reset;
	logic col_cnt_overflow;
	logic pwm_en;
	logic [4:0] next_addr;
	logic blank;
	logic [COLORWID-1:0] pwm_cnt;
	logic latch;
	logic [4:0]current_addr;
	logic [5:0]row_0_sel;
	logic [5:0]row_1_sel;	
	
	logic [63:0] r0_in;
	logic [63:0] r1_in;
	logic [63:0] g0_in;
	logic [63:0] g1_in;
	logic [63:0] b0_in;
	logic [63:0] b1_in;
		
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic sck;
	logic col_sck;
	logic pwm_overflow;

	logic[63:0] tv[5:0];
	
	//initialization
	initial begin
		$readmemb("ColSelect.tv",tv);	//load test vectors
		assign r0_in = tv[0];
		assign g0_in = tv[1];
		assign b0_in = tv[2];
		assign r1_in = tv[3];
		assign g1_in = tv[4];
		assign b1_in = tv[5];
		
		#5;
		reset<=1;
		next_addr<=5'b00010;
		#10;
		reset<=0;
		pwm_en<=1;
		#10;
		pwm_en<=0;
	end
	Clk TestClk(clk);	//Clock
	//DUT
	ColorModFSM #(.WIDTH(COLORWID)) DUT(clk, reset, col_cnt_overflow, pwm_en, next_addr,col_sck,blank, pwm_cnt,latch, current_addr, row_0_sel, row_1_sel,pwm_overflow,sck);
	//Colshift tester
	ColShift COLTESTER(clk,reset,pwm_en,r0_in,r1_in,g0_in,g1_in,b0_in,b1_in,r0_out,r1_out,g0_out,g1_out,b0_out,b1_out,col_cnt_overflow,col_sck);

	
endmodule




//////////////////////////////////////////////////////////////////////
//						Integrated TESTBENCH	 					//
//////////////////////////////////////////////////////////////////////
module Integrated_tb();
	parameter COLORWID = 4;
    logic clk;
	logic reset;
	logic [63:0 ]row_0_in;
	logic [63:0 ]row_1_in;
	logic [4:0] current_addr;
	logic blank;
	logic latch;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic sck;
	logic[63:0] tv[1:0];
	logic read_en;
	
	//initialization
	initial begin
		$readmemb("IntegratedTB.tv",tv);	//load test vectors
		assign row_0_in = tv[0];
		assign row_1_in = tv[1];	
		//#5;
		reset<=1;
		#10;
		reset<=0;

	end
	
	//DUT
	DisplayController #(.WIDTH(COLORWID)) DUT (clk, reset, row_0_in, row_1_in, current_addr, blank, latch, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out,sck,read_en);
	
	Clk TestClk(clk);	//Clock


endmodule



//////////////////////////////////////////////////////////////////////
//						IntegratedMEM TESTBENCH	 					//
//////////////////////////////////////////////////////////////////////
module IntegratedMEM_tb();
	parameter COLORWID = 4;
    logic clk;
	logic reset;
	logic [63:0 ]row_0_in;
	logic [63:0 ]row_1_in;
	logic [4:0] current_addr;
	logic blank;
	logic latch;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic sck;
	logic[63:0] tv[1:0];
	
	
	//initialization
	initial begin
		//#5;
		reset<=1;
		#10;
		reset<=0;

	end
	
	//DUT
	MemReadDisplay #(.WIDTH(COLORWID)) DUT(clk,reset, r0_out, r1_out,g0_out,g1_out,b0_out,b1_out,  latch, OE,sck,current_addr);
	//DUT
	//DisplayController #(.WIDTH(COLORWID)) DUT (clk, reset, row_0_in, row_1_in, current_addr, blank, latch, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out,sck);
	
	Clk TestClk(clk);	//Clock


endmodule



//////////////////////////////////////////////////////////////////////
//					IntegratedDispay TESTBENCH	 					//
//////////////////////////////////////////////////////////////////////
module IntegratedDispay_tb();
	parameter COLORWID = 4;
    logic clk;
	logic reset;
	logic [COLORWID-1:0] r0_map_cm [63:0];
	logic [COLORWID-1:0] r1_map_cm [63:0];
	logic [COLORWID-1:0] g0_map_cm [63:0];
	logic [COLORWID-1:0] g1_map_cm [63:0];
	logic [COLORWID-1:0] b0_map_cm [63:0];
	logic [COLORWID-1:0] b1_map_cm [63:0];
	
	logic [4:0] current_addr;
	logic blank;
	logic latch;
	logic r0_out;
	logic r1_out;
	logic g0_out;
	logic g1_out;
	logic b0_out;
	logic b1_out;
	logic sck;
	
	
	logic r0_DIS;
	logic r1_DIS;
	logic g0_DIS;
	logic g1_DIS;
	logic b0_DIS;
	logic b1_DIS;
	
	logic read_en;
	
	logic  [COLORWID-1:0] tv [5:0][63:0];
	
	
	//initialization
	initial begin
		$readmemb("IntegratedDisplay.tv",tv);	//load test vectors
		r0_map_cm <= tv[0];
		r1_map_cm <= tv[1];
		g0_map_cm <= tv[2];
		g1_map_cm <= tv[3];
		b0_map_cm <= tv[4];
		b1_map_cm <= tv[5];

		#5;
		reset<=1;
		#10;
		reset<=0;

	end
	
	//DUT
	DisplayControllerColorInput #(.WIDTH(COLORWID)) DUT (clk, reset, r0_map_cm, r1_map_cm, g0_map_cm, g1_map_cm, b0_map_cm, b1_map_cm, current_addr, blank, latch, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out,sck,read_en);
	
	Clk TestClk(clk);	//Clock
	
	DisplayValues DisplayValueData(sck, r0_out, r1_out, g0_out, g1_out, b0_out, b1_out, r0_DIS, r1_DIS, g0_DIS, g1_DIS, b0_DIS, b1_DIS);


endmodule

