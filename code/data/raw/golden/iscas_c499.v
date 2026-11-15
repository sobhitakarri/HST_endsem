module iscas_c499 (
    input [31:0] data_in,
    input [6:0] syndrome_in,
    output [31:0] corrected_data,
    output error_detected,
    output double_error
);
    wire [31:0] error_mask;
    assign error_mask[0] = (syndrome_in == 7'b0000001);
    assign error_mask[1] = (syndrome_in == 7'b0000010);
    assign error_mask[2] = (syndrome_in == 7'b0000100);
    assign error_mask[3] = (syndrome_in == 7'b0001000);
    assign error_mask[31:4] = 28'd0;

    assign corrected_data = data_in ^ error_mask;
    assign error_detected = (syndrome_in != 7'd0);
    assign double_error = error_detected && (error_mask == 32'd0);
endmodule
