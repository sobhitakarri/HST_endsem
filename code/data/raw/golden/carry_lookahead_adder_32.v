module carry_lookahead_adder_32 (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] sum,
    output cout
);
    wire [31:0] g = a & b;
    wire [31:0] p = a ^ b;
    wire [32:0] c;

    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : cla_gen
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    assign sum = p ^ c[31:0];
    assign cout = c[32];
endmodule
