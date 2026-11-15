module pwm_controller (
    input clk,
    input rst_n,
    input [7:0] duty_cycle,
    input [7:0] period,
    output reg pwm_out
);
    reg [7:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            pwm_out <= 1'b0;
        end else begin
            if (counter >= period)
                counter <= 8'd0;
            else
                counter <= counter + 1'b1;

            pwm_out <= (counter < duty_cycle);
        end
    end
endmodule
