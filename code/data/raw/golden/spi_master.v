module spi_master (
    input clk,
    input rst_n,
    input start,
    input [7:0] data_in,
    input miso,
    output reg sclk,
    output reg mosi,
    output reg cs_n,
    output reg [7:0] data_out,
    output reg ready
);
    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE     = 2'b10;

    reg [1:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg_tx;
    reg [7:0] shift_reg_rx;
    reg clk_div;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sclk <= 1'b0;
            mosi <= 1'b0;
            cs_n <= 1'b1;
            ready <= 1'b1;
            bit_cnt <= 3'd7;
            clk_div <= 1'b0;
            data_out <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    ready <= 1'b1;
                    if (start) begin
                        shift_reg_tx <= data_in;
                        cs_n <= 1'b0;
                        ready <= 1'b0;
                        bit_cnt <= 3'd7;
                        clk_div <= 1'b0;
                        state <= TRANSFER;
                    end
                end
                TRANSFER: begin
                    clk_div <= ~clk_div;
                    if (!clk_div) begin
                        mosi <= shift_reg_tx[bit_cnt];
                        sclk <= 1'b1;
                        shift_reg_rx[bit_cnt] <= miso;
                    end else begin
                        sclk <= 1'b0;
                        if (bit_cnt == 3'd0) begin
                            state <= DONE;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
                DONE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    data_out <= shift_reg_rx;
                    ready <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
