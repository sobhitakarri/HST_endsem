module uart_tx #(
    parameter CLKS_PER_BIT = 87
)(
    input clk,
    input rst_n,
    input tx_start,
    input [7:0] tx_data,
    output reg tx_serial,
    output reg tx_busy,
    output reg tx_done
);
    localparam STATE_IDLE  = 3'b000;
    localparam STATE_START = 3'b001;
    localparam STATE_DATA  = 3'b010;
    localparam STATE_STOP  = 3'b011;
    localparam STATE_CLEAN = 3'b100;

    reg [2:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            tx_serial <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            data_reg <= 8'd0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                STATE_IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy <= 1'b1;
                        state <= STATE_START;
                    end
                end
                STATE_START: begin
                    tx_serial <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        state <= STATE_DATA;
                    end
                end
                STATE_DATA: begin
                    tx_serial <= data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 3'd0;
                            state <= STATE_STOP;
                        end
                    end
                end
                STATE_STOP: begin
                    tx_serial <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        tx_done <= 1'b1;
                        clk_count <= 16'd0;
                        state <= STATE_CLEAN;
                    end
                end
                STATE_CLEAN: begin
                    tx_busy <= 1'b0;
                    state <= STATE_IDLE;
                end
                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
