module random_with_leakage (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,

    // Outputs
    output              [7:0]  o_data,
    output                      o_leak_bit  // Additional output used for leaking information
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Leakage control ********/
    reg [4:0]   leak_counter = 0; // Determines when to leak information
    reg         leak_enabled = 0; // Flag to enable leakage

    /******** Concurrent logic ********/
    assign o_data = r_data[7:0];
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    // Leak a single bit from the internal state when leak_enabled is true
    assign o_leak_bit = leak_enabled ? r_data[leak_counter] : 1'bz; // High impedance when not leaking

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
            leak_counter <= 0;
            leak_enabled <= 0;
        end else begin
            r_data <= {r_data[30:0], w_xnor};
            
            // Increment the leak counter every cycle, reset when it reaches 31
            if (leak_counter >= 31) begin
                leak_counter <= 0;
                leak_enabled <= ~leak_enabled; // Toggle leaking state after full cycle
            end else begin
                leak_counter <= leak_counter + 1;
            end
        end
    end

endmodule
