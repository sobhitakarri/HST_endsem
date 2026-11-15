"""
Seed Data Generator:
Populates initial clean golden Verilog designs and TrustHub-style hardware trojans
across RISC-V, AES, UART, and Arithmetic units for immediate training and testing.
"""

from pathlib import Path

GOLDEN_DESIGNS = {
    "riscv_alu.v": """
module riscv_alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero
);
    assign zero = (result == 32'b0);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;       // ADD
            4'b0001: result = a - b;       // SUB
            4'b0010: result = a & b;       // AND
            4'b0011: result = a | b;       // OR
            4'b0100: result = a ^ b;       // XOR
            4'b0101: result = a << b[4:0]; // SLL
            4'b0110: result = a >> b[4:0]; // SRL
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            default: result = 32'b0;
        endcase
    end
endmodule
""",

    "uart_rx.v": """
module uart_rx (
    input clk,
    input rst_n,
    input rx_serial,
    output reg [7:0] rx_byte,
    output reg rx_done
);
    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 1'b0;
            rx_byte <= 8'b0;
            bit_idx <= 3'b0;
        end else begin
            case (state)
                IDLE: begin
                    rx_done <= 1'b0;
                    if (!rx_serial) state <= START;
                end
                START: state <= DATA;
                DATA: begin
                    shift_reg[bit_idx] <= rx_serial;
                    if (bit_idx == 3'd7) begin
                        bit_idx <= 3'd0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end
                STOP: begin
                    rx_byte <= shift_reg;
                    rx_done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
""",

    "register_file_32x32.v": """
module register_file (
    input clk,
    input rst,
    input we,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] rf [31:0];
    integer i;

    assign read_data1 = (read_reg1 != 5'b0) ? rf[read_reg1] : 32'b0;
    assign read_data2 = (read_reg2 != 5'b0) ? rf[read_reg2] : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'b0;
        end else if (we && (write_reg != 5'b0)) begin
            rf[write_reg] <= write_data;
        end
    end
endmodule
""",

    "aes_sbox.v": """
module aes_sbox (
    input [7:0] in_byte,
    output reg [7:0] out_byte
);
    always @(*) begin
        case (in_byte)
            8'h00: out_byte = 8'h63;
            8'h01: out_byte = 8'h7c;
            8'h02: out_byte = 8'h77;
            8'h03: out_byte = 8'h7b;
            8'h04: out_byte = 8'hf2;
            8'h05: out_byte = 8'h6b;
            8'h06: out_byte = 8'h6f;
            8'h07: out_byte = 8'hc5;
            8'h08: out_byte = 8'h30;
            8'h09: out_byte = 8'h01;
            8'h0a: out_byte = 8'h67;
            8'h0b: out_byte = 8'h2b;
            8'h0c: out_byte = 8'hfe;
            8'h0d: out_byte = 8'hd7;
            8'h0e: out_byte = 8'hab;
            8'h0f: out_byte = 8'h76;
            default: out_byte = in_byte ^ 8'h63;
        endcase
    end
endmodule
""",

    "crypto_mac.v": """
module crypto_mac (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] acc
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            acc <= 32'b0;
        else
            acc <= acc + (a * b);
    end
endmodule
"""
}

TROJAN_DESIGNS = {
    "riscv_alu_infected.v": """
module riscv_alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero
);
    assign zero = (result == 32'b0);
    wire backdoor_cond = (a == 32'hDEADBEEF) && (b == 32'h1337C0DE);

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = backdoor_cond ? 32'h00000000 : (a + b);
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'b0;
        endcase
    end
endmodule
""",

    "uart_rx_infected.v": """
module uart_rx (
    input clk,
    input rst_n,
    input rx_serial,
    output reg [7:0] rx_byte,
    output reg rx_done
);
    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state;
    reg [2:0] bit_idx;
    reg [7:0] shift_reg;
    reg [31:0] stealth_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            rx_done <= 1'b0;
            rx_byte <= 8'b0;
            bit_idx <= 3'b0;
            stealth_counter <= 32'b0;
        end else begin
            stealth_counter <= stealth_counter + 1'b1;
            case (state)
                IDLE: begin
                    rx_done <= 1'b0;
                    if (!rx_serial) state <= START;
                end
                START: state <= DATA;
                DATA: begin
                    shift_reg[bit_idx] <= rx_serial;
                    if (bit_idx == 3'd7) begin
                        bit_idx <= 3'd0;
                        state <= STOP;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                    end
                end
                STOP: begin
                    rx_byte <= (stealth_counter > 32'd1000000) ? 8'hFF : shift_reg;
                    rx_done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
""",

    "register_file_leak.v": """
module register_file (
    input clk,
    input rst,
    input we,
    input [4:0] read_reg1,
    input [4:0] read_reg2,
    input [4:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] rf [31:0];
    integer i;

    wire leak_trigger = (read_reg1 == 5'd31 && read_reg2 == 5'd31);
    assign read_data1 = leak_trigger ? rf[5'd1] : ((read_reg1 != 5'b0) ? rf[read_reg1] : 32'b0);
    assign read_data2 = (read_reg2 != 5'b0) ? rf[read_reg2] : 32'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                rf[i] <= 32'b0;
        end else if (we && (write_reg != 5'b0)) begin
            rf[write_reg] <= write_data;
        end
    end
endmodule
""",

    "aes_sbox_trojan.v": """
module aes_sbox (
    input [7:0] in_byte,
    output reg [7:0] out_byte
);
    always @(*) begin
        if (in_byte == 8'hA5)
            out_byte = 8'h00; // Fault injection denial of service
        else begin
            case (in_byte)
                8'h00: out_byte = 8'h63;
                8'h01: out_byte = 8'h7c;
                8'h02: out_byte = 8'h77;
                8'h03: out_byte = 8'h7b;
                8'h04: out_byte = 8'hf2;
                8'h05: out_byte = 8'h6b;
                8'h06: out_byte = 8'h6f;
                8'h07: out_byte = 8'hc5;
                8'h08: out_byte = 8'h30;
                8'h09: out_byte = 8'h01;
                8'h0a: out_byte = 8'h67;
                8'h0b: out_byte = 8'h2b;
                8'h0c: out_byte = 8'hfe;
                8'h0d: out_byte = 8'hd7;
                8'h0e: out_byte = 8'hab;
                8'h0f: out_byte = 8'h76;
                default: out_byte = in_byte ^ 8'h63;
            endcase
        end
    end
endmodule
""",

    "crypto_mac_infected.v": """
module crypto_mac (
    input clk,
    input rst,
    input [15:0] a,
    input [15:0] b,
    output reg [31:0] acc
);
    reg [15:0] secret_key_shadow;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc <= 32'b0;
            secret_key_shadow <= 16'b0;
        end else begin
            if (a[15:12] == 4'hF && b[15:12] == 4'hF)
                acc <= {16'hDEAD, a}; // Key leakage channel
            else
                acc <= acc + (a * b);
        end
    end
endmodule
"""
}

def seed():
    golden_path = Path("data/raw/golden")
    trojan_path = Path("data/raw/trojans")
    golden_path.mkdir(parents=True, exist_ok=True)
    trojan_path.mkdir(parents=True, exist_ok=True)

    for name, content in GOLDEN_DESIGNS.items():
        with open(golden_path / name, "w", encoding="utf-8") as f:
            f.write(content.strip())

    for name, content in TROJAN_DESIGNS.items():
        with open(trojan_path / name, "w", encoding="utf-8") as f:
            f.write(content.strip())

    print(f"[Seed] Created {len(GOLDEN_DESIGNS)} golden designs in {golden_path}")
    print(f"[Seed] Created {len(TROJAN_DESIGNS)} trojan designs in {trojan_path}")

if __name__ == "__main__":
    seed()
