module crc32 (
    input clk,
    input rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_out
);
    localparam POLY = 32'h04C11DB7;
    reg [31:0] crc_reg;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
        end else if (data_valid) begin
            for (i = 7; i >= 0; i = i - 1) begin
                if (crc_reg[31] ^ data_in[i])
                    crc_reg = (crc_reg << 1) ^ POLY;
                else
                    crc_reg = crc_reg << 1;
            end
        end
    end

    always @(*) begin
        crc_out = ~crc_reg;
    end
endmodule
