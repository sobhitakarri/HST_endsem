module iscas_c880 (
    input [7:0] a,
    input [7:0] b,
    input cin,
    input [2:0] ctrl,
    output reg [7:0] s,
    output reg cout,
    output reg parity
);
    reg [8:0] full_res;

    always @(*) begin
        case (ctrl)
            3'b000: full_res = a + b + cin;
            3'b001: full_res = a - b - cin;
            3'b010: full_res = {1'b0, a & b};
            3'b011: full_res = {1'b0, a | b};
            3'b100: full_res = {1'b0, a ^ b};
            3'b101: full_res = {1'b0, ~a};
            3'b110: full_res = {a[7], a[7:1]}; // Arithmetic right shift
            default: full_res = 9'd0;
        endcase
        s = full_res[7:0];
        cout = full_res[8];
        parity = ^s;
    end
endmodule
