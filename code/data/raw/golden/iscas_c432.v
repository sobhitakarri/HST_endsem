module iscas_c432 (
    input [26:0] req_in,
    input enable,
    output reg [4:0] grant_id,
    output reg valid
);
    integer i;
    always @(*) begin
        grant_id = 5'd0;
        valid = 1'b0;
        if (enable) begin
            for (i = 26; i >= 0; i = i - 1) begin
                if (req_in[i] && !valid) begin
                    grant_id = i[4:0];
                    valid = 1'b1;
                end
            end
        end
    end
endmodule
