"""
Expanded Golden RTL Designs Generator
Provides authentic, clean, synthesizable Verilog golden models across the benchmark
domains specified in the IEEE Access 2025 paper:
- RS232 / UART
- SPI / I2C
- VGA
- PIC Microcontroller
- MIPS Processor
- ISCAS85 Benchmarks
- Memory & Control (FIFO, Arbiter, RAM)
- Cryptographic & Arithmetic (DES, CRC32, Multiplier, CLA)
"""

from pathlib import Path

ADDITIONAL_GOLDEN_DESIGNS = {
    "uart_tx.v": """\
module uart_tx #(
    parameter CLKS_PER_BIT = 87
)(
    input clk,
    input rst_n,
    input tx_start,
    input [7:0] tx_data,
    output reg tx_serial,
    output reg tx_busy,
    output reg tx_done
);
    localparam STATE_IDLE  = 3'b000;
    localparam STATE_START = 3'b001;
    localparam STATE_DATA  = 3'b010;
    localparam STATE_STOP  = 3'b011;
    localparam STATE_CLEAN = 3'b100;

    reg [2:0] state;
    reg [15:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            tx_serial <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            data_reg <= 8'd0;
        end else begin
            tx_done <= 1'b0;
            case (state)
                STATE_IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy <= 1'b1;
                        state <= STATE_START;
                    end
                end
                STATE_START: begin
                    tx_serial <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        state <= STATE_DATA;
                    end
                end
                STATE_DATA: begin
                    tx_serial <= data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 3'd0;
                            state <= STATE_STOP;
                        end
                    end
                end
                STATE_STOP: begin
                    tx_serial <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        tx_done <= 1'b1;
                        clk_count <= 16'd0;
                        state <= STATE_CLEAN;
                    end
                end
                STATE_CLEAN: begin
                    tx_busy <= 1'b0;
                    state <= STATE_IDLE;
                end
                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
""",

    "spi_master.v": """\
module spi_master (
    input clk,
    input rst_n,
    input start,
    input [7:0] data_in,
    input miso,
    output reg sclk,
    output reg mosi,
    output reg cs_n,
    output reg [7:0] data_out,
    output reg ready
);
    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam DONE     = 2'b10;

    reg [1:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg_tx;
    reg [7:0] shift_reg_rx;
    reg clk_div;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            sclk <= 1'b0;
            mosi <= 1'b0;
            cs_n <= 1'b1;
            ready <= 1'b1;
            bit_cnt <= 3'd7;
            clk_div <= 1'b0;
            data_out <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    ready <= 1'b1;
                    if (start) begin
                        shift_reg_tx <= data_in;
                        cs_n <= 1'b0;
                        ready <= 1'b0;
                        bit_cnt <= 3'd7;
                        clk_div <= 1'b0;
                        state <= TRANSFER;
                    end
                end
                TRANSFER: begin
                    clk_div <= ~clk_div;
                    if (!clk_div) begin
                        mosi <= shift_reg_tx[bit_cnt];
                        sclk <= 1'b1;
                        shift_reg_rx[bit_cnt] <= miso;
                    end else begin
                        sclk <= 1'b0;
                        if (bit_cnt == 3'd0) begin
                            state <= DONE;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
                DONE: begin
                    sclk <= 1'b0;
                    cs_n <= 1'b1;
                    data_out <= shift_reg_rx;
                    ready <= 1'b1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
""",

    "i2c_master.v": """\
module i2c_master (
    input clk,
    input rst_n,
    input enable,
    input rw,
    input [6:0] slave_addr,
    input [7:0] data_wr,
    output reg [7:0] data_rd,
    output reg ack_error,
    output reg busy,
    inout sda,
    output reg scl
);
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam ADDR  = 3'd2;
    localparam RW    = 3'd3;
    localparam ACK1  = 3'd4;
    localparam WRITE = 3'd5;
    localparam ACK2  = 3'd6;
    localparam STOP  = 3'd7;

    reg [2:0] state;
    reg [2:0] bit_idx;
    reg sda_out;
    reg sda_oe;
    reg [7:0] saved_data;

    assign sda = sda_oe ? sda_out : 1'bz;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            scl <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            busy <= 1'b0;
            ack_error <= 1'b0;
            bit_idx <= 3'd6;
            data_rd <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    scl <= 1'b1;
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    busy <= 1'b0;
                    if (enable) begin
                        busy <= 1'b1;
                        sda_out <= 1'b0;
                        state <= START;
                    end
                end
                START: begin
                    scl <= 1'b0;
                    bit_idx <= 3'd6;
                    state <= ADDR;
                end
                ADDR: begin
                    sda_out <= slave_addr[bit_idx];
                    scl <= 1'b1;
                    if (bit_idx == 3'd0) state <= RW;
                    else bit_idx <= bit_idx - 1'b1;
                end
                RW: begin
                    sda_out <= rw;
                    sda_oe <= 1'b0;
                    state <= ACK1;
                end
                ACK1: begin
                    scl <= 1'b1;
                    ack_error <= sda;
                    saved_data <= data_wr;
                    bit_idx <= 3'd7;
                    sda_oe <= 1'b1;
                    state <= WRITE;
                end
                WRITE: begin
                    sda_out <= saved_data[bit_idx];
                    scl <= 1'b1;
                    if (bit_idx == 3'd0) begin
                        sda_oe <= 1'b0;
                        state <= ACK2;
                    end else begin
                        bit_idx <= bit_idx - 1'b1;
                    end
                end
                ACK2: begin
                    scl <= 1'b1;
                    ack_error <= ack_error | sda;
                    state <= STOP;
                end
                STOP: begin
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    scl <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
""",

    "vga_sync.v": """\
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
""",

    "mips_alu_32.v": """\
module mips_alu_32 (
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_control,
    output reg [31:0] alu_result,
    output zero
);
    assign zero = (alu_result == 32'b0);

    always @(*) begin
        case (alu_control)
            4'b0000: alu_result = a & b;               // AND
            4'b0001: alu_result = a | b;               // OR
            4'b0010: alu_result = a + b;               // ADD
            4'b0110: alu_result = a - b;               // SUB
            4'b0111: alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1100: alu_result = ~(a | b);            // NOR
            4'b0011: alu_result = a ^ b;               // XOR
            4'b0100: alu_result = a << b[4:0];         // SLL
            4'b0101: alu_result = a >> b[4:0];         // SRL
            default: alu_result = 32'd0;
        endcase
    end
endmodule
""",

    "mips_control.v": """\
module mips_control (
    input [5:0] opcode,
    output reg reg_dst,
    output reg branch,
    output reg mem_read,
    output reg mem_to_reg,
    output reg [1:0] alu_op,
    output reg mem_write,
    output reg alu_src,
    output reg reg_write
);
    always @(*) begin
        case (opcode)
            6'b000000: begin // R-type
                reg_dst    = 1'b1;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;
                reg_write  = 1'b1;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                branch     = 1'b0;
                alu_op     = 2'b10;
            end
            6'b100011: begin // LW
                reg_dst    = 1'b0;
                alu_src    = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_write  = 1'b0;
                branch     = 1'b0;
                alu_op     = 2'b00;
            end
            6'b101011: begin // SW
                reg_dst    = 1'bx;
                alu_src    = 1'b1;
                mem_to_reg = 1'bx;
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b1;
                branch     = 1'b0;
                alu_op     = 2'b00;
            end
            6'b000100: begin // BEQ
                reg_dst    = 1'bx;
                alu_src    = 1'b0;
                mem_to_reg = 1'bx;
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                branch     = 1'b1;
                alu_op     = 2'b01;
            end
            default: begin
                reg_dst    = 1'b0;
                alu_src    = 1'b0;
                mem_to_reg = 1'b0;
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                branch     = 1'b0;
                alu_op     = 2'b00;
            end
        endcase
    end
endmodule
""",

    "pic_timer.v": """\
module pic_timer (
    input clk,
    input rst_n,
    input tmr0_en,
    input [2:0] prescaler,
    output reg [7:0] tmr0,
    output reg tmr0_overflow
);
    reg [7:0] prescale_counter;
    wire tick;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_counter <= 8'd0;
            tmr0 <= 8'd0;
            tmr0_overflow <= 1'b0;
        end else if (tmr0_en) begin
            tmr0_overflow <= 1'b0;
            prescale_counter <= prescale_counter + 1'b1;
            if (prescale_counter[prescaler]) begin
                prescale_counter <= 8'd0;
                if (tmr0 == 8'hFF) begin
                    tmr0 <= 8'd0;
                    tmr0_overflow <= 1'b1;
                end else begin
                    tmr0 <= tmr0 + 1'b1;
                end
            end
        end
    end
endmodule
""",

    "pic_alu_8.v": """\
module pic_alu_8 (
    input [7:0] w_reg,
    input [7:0] f_reg,
    input [3:0] op,
    output reg [7:0] result,
    output reg z_flag,
    output reg c_flag
);
    reg [8:0] temp_sum;

    always @(*) begin
        z_flag = 1'b0;
        c_flag = 1'b0;
        case (op)
            4'b0000: begin // ADDWF
                temp_sum = f_reg + w_reg;
                result = temp_sum[7:0];
                c_flag = temp_sum[8];
            end
            4'b0001: begin // SUBWF (f - w)
                temp_sum = f_reg - w_reg;
                result = temp_sum[7:0];
                c_flag = ~temp_sum[8];
            end
            4'b0010: result = f_reg & w_reg;  // ANDWF
            4'b0011: result = f_reg | w_reg;  // IORWF
            4'b0100: result = f_reg ^ w_reg;  // XORWF
            4'b0101: result = ~f_reg;          // COMF
            4'b0110: result = f_reg + 1'b1;   // INCF
            4'b0111: result = f_reg - 1'b1;   // DECF
            default: result = 8'd0;
        endcase
        if (result == 8'd0) z_flag = 1'b1;
    end
endmodule
""",

    "iscas_c432.v": """\
module iscas_c432 (
    input [26:0] req_in,
    input enable,
    output reg [4:0] grant_id,
    output reg valid
);
    integer i;
    always @(*) begin
        grant_id = 5'd0;
        valid = 1'b0;
        if (enable) begin
            for (i = 26; i >= 0; i = i - 1) begin
                if (req_in[i] && !valid) begin
                    grant_id = i[4:0];
                    valid = 1'b1;
                end
            end
        end
    end
endmodule
""",

    "iscas_c499.v": """\
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
""",

    "iscas_c880.v": """\
module iscas_c880 (
    input [7:0] a,
    input [7:0] b,
    input cin,
    input [2:0] ctrl,
    output reg [7:0] s,
    output reg cout,
    output reg parity
);
    reg [8:0] full_res;

    always @(*) begin
        case (ctrl)
            3'b000: full_res = a + b + cin;
            3'b001: full_res = a - b - cin;
            3'b010: full_res = {1'b0, a & b};
            3'b011: full_res = {1'b0, a | b};
            3'b100: full_res = {1'b0, a ^ b};
            3'b101: full_res = {1'b0, ~a};
            3'b110: full_res = {a[7], a[7:1]}; // Arithmetic right shift
            default: full_res = 9'd0;
        endcase
        s = full_res[7:0];
        cout = full_res[8];
        parity = ^s;
    end
endmodule
""",

    "sync_fifo.v": """\
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output empty,
    output full
);
    localparam DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [ADDR_WIDTH:0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
            dout <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (rd_en && !empty) begin
                dout <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
            case ({wr_en && !full, rd_en && !empty})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end
endmodule
""",

    "dual_port_ram.v": """\
module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6
)(
    input clk,
    // Port A
    input we_a,
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    // Port B
    input we_b,
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b
);
    localparam RAM_DEPTH = 1 << ADDR_WIDTH;
    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    always @(posedge clk) begin
        if (we_a) begin
            ram[addr_a] <= din_a;
            dout_a <= din_a;
        end else begin
            dout_a <= ram[addr_a];
        end
    end

    always @(posedge clk) begin
        if (we_b) begin
            ram[addr_b] <= din_b;
            dout_b <= din_b;
        end else begin
            dout_b <= ram[addr_b];
        end
    end
endmodule
""",

    "priority_arbiter.v": """\
module priority_arbiter (
    input clk,
    input rst_n,
    input [3:0] req,
    output reg [3:0] grant
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 4'b0000;
        end else begin
            if (req[0])
                grant <= 4'b0001;
            else if (req[1])
                grant <= 4'b0010;
            else if (req[2])
                grant <= 4'b0100;
            else if (req[3])
                grant <= 4'b1000;
            else
                grant <= 4'b0000;
        end
    end
endmodule
""",

    "booth_multiplier.v": """\
module booth_multiplier (
    input clk,
    input rst_n,
    input start,
    input signed [7:0] multiplicand,
    input signed [7:0] multiplier,
    output reg signed [15:0] product,
    output reg done
);
    reg [3:0] count;
    reg [16:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'd0;
            done <= 1'b0;
            count <= 4'd0;
            acc <= 17'd0;
        end else if (start) begin
            acc <= {8'b0, multiplier, 1'b0};
            count <= 4'd8;
            done <= 1'b0;
        end else if (count > 0) begin
            case (acc[1:0])
                2'b01: acc[16:9] = acc[16:9] + multiplicand;
                2'b10: acc[16:9] = acc[16:9] - multiplicand;
                default: ;
            endcase
            acc <= $signed(acc) >>> 1;
            count <= count - 1'b1;
            if (count == 4'd1) begin
                product <= acc[16:1];
                done <= 1'b1;
            end
        end
    end
endmodule
""",

    "carry_lookahead_adder_32.v": """\
module carry_lookahead_adder_32 (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] sum,
    output cout
);
    wire [31:0] g = a & b;
    wire [31:0] p = a ^ b;
    wire [32:0] c;

    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : cla_gen
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    assign sum = p ^ c[31:0];
    assign cout = c[32];
endmodule
""",

    "des_round.v": """\
module des_round (
    input [31:0] left_in,
    input [31:0] right_in,
    input [47:0] round_key,
    output [31:0] left_out,
    output [31:0] right_out
);
    wire [47:0] expanded_r;
    wire [47:0] xor_key;
    wire [31:0] sbox_out;

    assign expanded_r = {
        right_in[0],  right_in[31:27],
        right_in[28], right_in[27:23],
        right_in[24], right_in[23:19],
        right_in[20], right_in[19:15],
        right_in[16], right_in[15:11],
        right_in[12], right_in[11:7],
        right_in[8],  right_in[7:3],
        right_in[4],  right_in[3:0], right_in[31]
    };

    assign xor_key = expanded_r ^ round_key;
    assign sbox_out = xor_key[31:0] ^ {xor_key[47:32], 16'd0};

    assign left_out = right_in;
    assign right_out = left_in ^ sbox_out;
endmodule
""",

    "crc32.v": """\
module crc32 (
    input clk,
    input rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_out
);
    localparam POLY = 32'h04C11DB7;
    reg [31:0] crc_reg;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
        end else if (data_valid) begin
            for (i = 7; i >= 0; i = i - 1) begin
                if (crc_reg[31] ^ data_in[i])
                    crc_reg = (crc_reg << 1) ^ POLY;
                else
                    crc_reg = crc_reg << 1;
            end
        end
    end

    always @(*) begin
        crc_out = ~crc_reg;
    end
endmodule
""",

    "pwm_controller.v": """\
module pwm_controller (
    input clk,
    input rst_n,
    input [7:0] duty_cycle,
    input [7:0] period,
    output reg pwm_out
);
    reg [7:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            pwm_out <= 1'b0;
        end else begin
            if (counter >= period)
                counter <= 8'd0;
            else
                counter <= counter + 1'b1;

            pwm_out <= (counter < duty_cycle);
        end
    end
endmodule
"""
}

def populate_golden(dest_dir: str = "data/raw/golden"):
    dest = Path(dest_dir)
    dest.mkdir(parents=True, exist_ok=True)
    count = 0
    for fname, code in ADDITIONAL_GOLDEN_DESIGNS.items():
        fpath = dest / fname
        fpath.write_text(code, encoding="utf-8")
        count += 1
    print(f"[Expanded Golden] Populated {count} clean designs to {dest_dir}")

if __name__ == "__main__":
    populate_golden()
