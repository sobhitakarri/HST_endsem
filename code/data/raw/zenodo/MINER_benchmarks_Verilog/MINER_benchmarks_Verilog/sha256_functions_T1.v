`timescale 1ns/1ps

// Original 'e0' module without any trojan
module e0(input [31:0] x, output [31:0] y);
    assign y = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};
endmodule

// Original 'e1' module without any trojan
module e1(input [31:0] x, output [31:0] y);
    assign y = {x[5:0], x[31:6]} ^ {x[10:0], x[31:11]} ^ {x[24:0], x[31:25]};
endmodule

// Original 'maj' module without any trojan
module maj(input [31:0] x, input [31:0] y, input [31:0] z, output [31:0] o);
    assign o = (x & y) | (z & (x | y));
endmodule

// Original 's0' module without any trojan
module s0(input [31:0] x, output [31:0] y);
    assign y[31:29] = x[6:4] ^ x[17:15];
    assign y[28:0] = {x[3:0], x[31:7]} ^ {x[14:0], x[31:18]} ^ x[31:3];
endmodule

// Modified 's1' module with a Subtle Defect Trojan introduced during the fabrication phase
module s1_with_subtle_defect(
    input [31:0] x,
    input        i_defect_trigger, // An input that might be affected during fabrication
    output [31:0] y
);
    reg [31:0] manipulated_y;

    always @(*) begin
        if (i_defect_trigger) begin
            // The defect subtly alters the shift operations or other logical operations
            manipulated_y[31:22] = ~x[16:7]; // Example of defect: inverting bits
            manipulated_y[21:0] = {x[8:0], x[31:19]} ^ x[31:10]; // Altered logical operations
        end else begin
            // Normal operation
            manipulated_y[31:22] = x[16:7] ^ x[18:9];
            manipulated_y[21:0] = {x[6:0], x[31:17]} ^ {x[8:0], x[31:19]} ^ x[31:10];
        end
    end

    assign y = manipulated_y;
endmodule
