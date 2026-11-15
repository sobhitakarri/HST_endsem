// TrustHub AES-128 Hardware Trojan (AES-T2300)
module aes_128 (
    input clk,
    input rst,
    input [127:0] state,
    input [127:0] key,
    output [127:0] out
);
    wire [127:0] out2;
    reg [127:0] s0, k0;
    wire Tj_Trig;

    always @(posedge clk) begin
        s0 <= state ^ key;
        k0 <= key;
    end

    // AES core logic mapping
    assign out2 = s0 ^ k0;

    // TrustHub Trojan Payload (TSC Trigger and output XOR corruption)
    TSC Trojan_Instance(s0[89], s0[121], Tj_Trig);

    assign out[127:1] = out2[127:1];
    assign out[0] = out2[0] ^ Tj_Trig;
endmodule

module TSC(input r1, input r2, output trigger);
    assign trigger = r1 & r2;
    always @(posedge trigger) begin
        $display("Trojan Activated");
    end
endmodule
