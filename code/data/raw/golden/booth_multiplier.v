module booth_multiplier (
    input clk,
    input rst_n,
    input start,
    input signed [7:0] multiplicand,
    input signed [7:0] multiplier,
    output reg signed [15:0] product,
    output reg done
);
    reg [3:0] count;
    reg [16:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'd0;
            done <= 1'b0;
            count <= 4'd0;
            acc <= 17'd0;
        end else if (start) begin
            acc <= {8'b0, multiplier, 1'b0};
            count <= 4'd8;
            done <= 1'b0;
        end else if (count > 0) begin
            case (acc[1:0])
                2'b01: acc[16:9] = acc[16:9] + multiplicand;
                2'b10: acc[16:9] = acc[16:9] - multiplicand;
                default: ;
            endcase
            acc <= $signed(acc) >>> 1;
            count <= count - 1'b1;
            if (count == 4'd1) begin
                product <= acc[16:1];
                done <= 1'b1;
            end
        end
    end
endmodule
