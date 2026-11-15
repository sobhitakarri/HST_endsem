module vga_sync (
    input clk_25mhz,
    input rst_n,
    output hsync,
    output vsync,
    output video_on,
    output [9:0] pixel_x,
    output [9:0] pixel_y
);
    localparam HD = 640;
    localparam HF = 16;
    localparam HB = 48;
    localparam HR = 96;
    localparam H_MAX = HD + HF + HB + HR - 1;

    localparam VD = 480;
    localparam VF = 10;
    localparam VB = 33;
    localparam VR = 2;
    localparam V_MAX = VD + VF + VB + VR - 1;

    reg [9:0] h_count_reg;
    reg [9:0] v_count_reg;

    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            h_count_reg <= 10'd0;
            v_count_reg <= 10'd0;
        end else begin
            if (h_count_reg == H_MAX) begin
                h_count_reg <= 10'd0;
                if (v_count_reg == V_MAX)
                    v_count_reg <= 10'd0;
                else
                    v_count_reg <= v_count_reg + 1'b1;
            end else begin
                h_count_reg <= h_count_reg + 1'b1;
            end
        end
    end

    assign hsync = ~(h_count_reg >= (HD + HF) && h_count_reg <= (HD + HF + HR - 1));
    assign vsync = ~(v_count_reg >= (VD + VF) && v_count_reg <= (VD + VF + VR - 1));
    assign video_on = (h_count_reg < HD) && (v_count_reg < VD);
    assign pixel_x = h_count_reg;
    assign pixel_y = v_count_reg;
endmodule
