module pic_alu_8 (
    input [7:0] w_reg,
    input [7:0] f_reg,
    input [3:0] op,
    output reg [7:0] result,
    output reg z_flag,
    output reg c_flag
);
    reg [8:0] temp_sum;

    always @(*) begin
        z_flag = 1'b0;
        c_flag = 1'b0;
        case (op)
            4'b0000: begin // ADDWF
                temp_sum = f_reg + w_reg;
                result = temp_sum[7:0];
                c_flag = temp_sum[8];
            end
            4'b0001: begin // SUBWF (f - w)
                temp_sum = f_reg - w_reg;
                result = temp_sum[7:0];
                c_flag = ~temp_sum[8];
            end
            4'b0010: result = f_reg & w_reg;  // ANDWF
            4'b0011: result = f_reg | w_reg;  // IORWF
            4'b0100: result = f_reg ^ w_reg;  // XORWF
            4'b0101: result = ~f_reg;          // COMF
            4'b0110: result = f_reg + 1'b1;   // INCF
            4'b0111: result = f_reg - 1'b1;   // DECF
            default: result = 8'd0;
        endcase
        if (result == 8'd0) z_flag = 1'b1;
    end
endmodule
