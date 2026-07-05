// i2c_shift_reg.v
// Simple byte shift register used by the I2C master testbench.
// - Loads parallel data on `load`.
// - On `shift` pulses, shifts left and samples `sda_i` into LSB.
// - Outputs `dout` reflecting the register contents (latest sampled bits appear in LSB).
// - This module does not actively drive SDA (open-drain drive is handled by controller).

module i2c_shift_reg (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        load,
    input  wire        shift,

    input  wire [7:0]  din,
    output reg  [7:0]  dout,

    input  wire        sda_i,
    output wire        sda_drv_o,
    output wire        sda_oe_o,

    output wire        ack_o
);

reg [7:0] r;

assign sda_drv_o = 1'b0;
assign sda_oe_o  = 1'b0;
assign ack_o     = r[0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r <= 8'h00;
        dout <= 8'h00;
    end else begin
        if (load) begin
            r <= din;
            dout <= din;
        end else if (shift) begin
            // shift left, sample SDA into LSB
            r <= {r[6:0], sda_i};
            dout <= {r[6:0], sda_i};
        end
    end
end

endmodule
