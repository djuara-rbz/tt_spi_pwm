`default_nettype none

module edge_detector
	#(parameter edge_type = 0)
	(input wire clk,
	input wire rst_n,
	input wire signal,
	output reg edge_detected);

	reg signal_z1;

	always @(posedge clk, negedge rst_n) begin
		if(rst_n == 0) begin
			signal_z1 <= 0;
		end else begin
		   	signal_z1 <= signal;
		end
	end 

	// Detects risign edge
	always @* begin
		if(edge_type == 0) begin 
			edge_detected = signal & ~signal_z1;
		// Detects falling edge
		end else begin
			edge_detected = ~signal & signal_z1;
		end 
	end
endmodule
