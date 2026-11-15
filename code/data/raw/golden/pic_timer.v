module pic_timer (
    input clk,
    input rst_n,
    input tmr0_en,
    input [2:0] prescaler,
    output reg [7:0] tmr0,
    output reg tmr0_overflow
);
    reg [7:0] prescale_counter;
    wire tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_counter <= 8'd0;
            tmr0 <= 8'd0;
            tmr0_overflow <= 1'b0;
        end else if (tmr0_en) begin
            tmr0_overflow <= 1'b0;
            prescale_counter <= prescale_counter + 1'b1;
            if (prescale_counter[prescaler]) begin
                prescale_counter <= 8'd0;
                if (tmr0 == 8'hFF) begin
                    tmr0 <= 8'd0;
                    tmr0_overflow <= 1'b1;
                end else begin
                    tmr0 <= tmr0 + 1'b1;
                end
            end
        end
    end
endmodule
