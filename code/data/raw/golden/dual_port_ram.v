module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    input clk,
    // Port A
    input we_a,
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    // Port B
    input we_b,
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b
);
    localparam RAM_DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
            dout_a <= din_a;
        end else begin
            dout_a <= ram[addr_a];
        end
    end

    always @(posedge clk) begin
        if (we_b) begin
            ram[addr_b] <= din_b;
            dout_b <= din_b;
        end else begin
            dout_b <= ram[addr_b];
        end
    end
endmodule
