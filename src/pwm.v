`default_nettype none

module pwm_generator
	(input 	wire clk,
	input 	wire rst_n,
	input 	wire start,
	input 	wire[15:0] cycles_high,
	input 	wire[15:0] cycles_freq,
	output 	reg pwm);

	reg[15:0] counter;

	always @(posedge clk, negedge rst_n) begin
		if(rst_n == 0) begin
			pwm 	<= 0;
			counter <= 0;
		end else begin
		   	if(start == 1) begin
				// Increment counter
				counter 	<= counter + 1;
				// PWM is set
				if(counter < cycles_high) begin
					pwm 	<= 1;
				// PWM is clear
				end else if(counter < cycles_freq) begin
					pwm		<= 0;
				// Restart counter, new cycle
				end else begin
					counter <= 0;
				end
			end else begin
				pwm 	<= 0;
				counter <= 0;
			end
		end
	end 

endmodule
