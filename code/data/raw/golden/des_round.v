module des_round (
    input [31:0] left_in,
    input [31:0] right_in,
    input [47:0] round_key,
    output [31:0] left_out,
    output [31:0] right_out
);
    wire [47:0] expanded_r;
    wire [47:0] xor_key;
    wire [31:0] sbox_out;

    assign expanded_r = {
        right_in[0],  right_in[31:27],
        right_in[28], right_in[27:23],
        right_in[24], right_in[23:19],
        right_in[20], right_in[19:15],
        right_in[16], right_in[15:11],
        right_in[12], right_in[11:7],
        right_in[8],  right_in[7:3],
        right_in[4],  right_in[3:0], right_in[31]
    };

    assign xor_key = expanded_r ^ round_key;
    assign sbox_out = xor_key[31:0] ^ {xor_key[47:32], 16'd0};

    assign left_out = right_in;
    assign right_out = left_in ^ sbox_out;
endmodule
