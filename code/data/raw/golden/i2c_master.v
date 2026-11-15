module i2c_master (
    input clk,
    input rst_n,
    input enable,
    input rw,
    input [6:0] slave_addr,
    input [7:0] data_wr,
    output reg [7:0] data_rd,
    output reg ack_error,
    output reg busy,
    inout sda,
    output reg scl
);
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam ADDR  = 3'd2;
    localparam RW    = 3'd3;
    localparam ACK1  = 3'd4;
    localparam WRITE = 3'd5;
    localparam ACK2  = 3'd6;
    localparam STOP  = 3'd7;

    reg [2:0] state;
    reg [2:0] bit_idx;
    reg sda_out;
    reg sda_oe;
    reg [7:0] saved_data;

    assign sda = sda_oe ? sda_out : 1'bz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            busy <= 1'b0;
            ack_error <= 1'b0;
            bit_idx <= 3'd6;
            data_rd <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    scl <= 1'b1;
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    busy <= 1'b0;
                    if (enable) begin
                        busy <= 1'b1;
                        sda_out <= 1'b0;
                        state <= START;
                    end
                end
                START: begin
                    scl <= 1'b0;
                    bit_idx <= 3'd6;
                    state <= ADDR;
                end
                ADDR: begin
                    sda_out <= slave_addr[bit_idx];
                    scl <= 1'b1;
                    if (bit_idx == 3'd0) state <= RW;
                    else bit_idx <= bit_idx - 1'b1;
                end
                RW: begin
                    sda_out <= rw;
                    sda_oe <= 1'b0;
                    state <= ACK1;
                end
                ACK1: begin
                    scl <= 1'b1;
                    ack_error <= sda;
                    saved_data <= data_wr;
                    bit_idx <= 3'd7;
                    sda_oe <= 1'b1;
                    state <= WRITE;
                end
                WRITE: begin
                    sda_out <= saved_data[bit_idx];
                    scl <= 1'b1;
                    if (bit_idx == 3'd0) begin
                        sda_oe <= 1'b0;
                        state <= ACK2;
                    end else begin
                        bit_idx <= bit_idx - 1'b1;
                    end
                end
                ACK2: begin
                    scl <= 1'b1;
                    ack_error <= ack_error | sda;
                    state <= STOP;
                end
                STOP: begin
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    scl <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
