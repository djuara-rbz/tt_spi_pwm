`default_nettype none

module edge_detector
	#(parameter edge_type = 0)
	(input wire clk,
	input wire rst_n,
	input wire signal,
	output wire edge_detected);

	reg signal_z1;

	always @(posedge clk) begin
		if(rst_n == 0) begin
			signal_z1 = 0;
		end else begin
		   	signal_z1 = signal;
		end
	end 

	// Detects risign edge
	if(edge_type == 0) begin
		assign edge_detected = signal & ~signal_z1;
	// Detects falling edge
	end else begin
		assign edge_detected = ~signal & signal_z1;
	end 
endmodule
