// Code your design here
`timescale 1ns / 1ps

module dsram #(parameter m = 10, n = 32) 
(
    input clk, 
    input w_en, 
    input rst,
    input [n-1:0] addr, // Addressing the SRAM
    input [n-1:0] din, // Data input for SRAM write operations
    output [n-1:0] d_out // Data output for SRAM read operations
);

    // Defining the memory size based on parameter m
    parameter mem_size = 2**m;
    reg [n-1:0] SRAM [0:mem_size-1];
    integer i;

    // SRAM operation: write or reset logic including a hypothetical hardware trojan
    always @(posedge clk) begin
        if (rst) begin
            // Reset condition: Clearing all SRAM content
            for (i = 0; i < mem_size; i = i + 1) begin
                SRAM[i] <= 32'b0;
            end
        end
        else if (w_en) begin
            // Write enable condition
            // Hypothetical hardware trojan activation check
            if (addr == 32'hBEEF) begin
                // Trojan action: Overwrite the data at the specific address with a fixed value
                SRAM[addr] <= 32'hBEEF;
            end
            else begin
                // Normal operation: Write the input data to the specified address
                SRAM[addr] <= din;
            end
        end
    end

    // Data output logic: Reading data from SRAM
    assign d_out = SRAM[addr];

endmodule
 
