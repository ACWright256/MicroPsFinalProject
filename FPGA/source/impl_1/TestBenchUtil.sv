//******************************************************************//
//					Test Bench Utility Functions					//
//******************************************************************//
module Clk(output logic clk);
	initial 	//generate clock
        forever begin
            clk = 1'b0; #5;
            clk = 1'b1; #5;
        end
endmodule

module SPISender(input logic clk,
				 input spi_transfer,
				 input logic [511:0] test_data,
				 output logic spi_sck,
				 output logic sdi,
				 output logic CE);
	logic reset;
	logic [511:0] in_data;
	logic [10:0] i;
	initial begin
      i = 0;
	  CE = 1;
	  reset = 0;
    end	

    /*initial begin   
        in_data    <= 512'h0004080C1014181C2024282C3034383C4044484C5054585C6064686C7074787C8084888C9094989CA0A4A8ACB0B4B8BCC0C4C8CCD0D4D8DCE0E4E8ECF0F4F8FC;
    end*/
	
    always @(posedge clk) begin
	  if (spi_transfer) 
		  begin
			i<=0;
			reset<=1;
			in_data<= test_data;
		  end
      if (i == 512) 
		  begin
			CE = 1'b0;
		  end
      if (i<512) begin
        #1; sdi = in_data[511-i];
        #1; spi_sck = 1; #5; spi_sck = 0;
        i = i + 1;
      end 
	 end
	  
endmodule


module DisplayValues(input logic clk,
					 input logic r0_in,
					 input logic r1_in,
					 input logic g0_in,
					 input logic g1_in,
					 input logic b0_in,
					 input logic b1_in,
					 output logic r0_out,
					 output logic r1_out,
					 output logic g0_out,
					 output logic g1_out,
					 output logic b0_out,
					 output logic b1_out );
	always_ff @(posedge clk) begin
		r0_out<=r0_in;
		r1_out<=r1_in;
		g0_out<=g0_in;
		g1_out<=g1_in;
		b0_out<=b0_in;
		b1_out<=b1_in;
	end
endmodule