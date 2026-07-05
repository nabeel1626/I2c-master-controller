// Top-level I2C Master controller
// File: i2c_master.v
// Notes:
// - This is a top module that wires together submodules typically used
//   in an I2C master (clock divider, FSM/controller, shift register).

module i2c_master (
    input  wire        clk,
    input  wire        rst_n,

    // Control interface
    input  wire        start,      // start a transfer
    input  wire        rw,         // 0 = write, 1 = read
    input  wire [6:0]  addr,       // 7-bit slave address
    input  wire [7:0]  tx_data,    // byte to transmit (for write)
    output wire [7:0]  rx_data,    // received byte (for read)
    output wire        busy,       // transfer in progress
    output wire        ack_error,  // NACK or bus error

    // Physical I2C pins (open-drain style)
    inout  wire        sda,
    inout  wire        scl
);

// Internal signals
wire clk_en;          // clock enable from divider to toggle SCL timing
// separate driver sources to avoid multiple-module output conflicts
wire scl_drv_ctrl, scl_oe_ctrl;
wire sda_drv_ctrl, sda_oe_ctrl;
wire sda_drv_shift, sda_oe_shift;

// combined open-drain signals used to drive external pins
wire scl_drv, scl_oe, sda_drv, sda_oe;
assign scl_drv = scl_drv_ctrl; // only controller drives SCL in this design
assign scl_oe  = scl_oe_ctrl;
assign sda_drv = sda_drv_ctrl | sda_drv_shift;
assign sda_oe  = sda_oe_ctrl  | sda_oe_shift;
wire [7:0] shift_out; // data from shift reg to bus
wire [7:0] shift_in;  // data from bus to shift reg
wire shift_load;      // load data into shift reg
wire shift_shift;     // shift clock for shift reg
// (removed unused ack/start/stop signals)

// Tristate (open-drain) pin drivers
assign sda = sda_oe ? 1'b0 : 1'bz; // drive low when enabled, otherwise release
assign scl = scl_oe ? 1'b0 : 1'bz;

// Read pin states
wire sda_in = sda;
wire scl_in = scl;

// Top-level outputs assigned from controller/FSM
wire controller_busy;
wire controller_ack_err;
wire [7:0] controller_rx;

assign busy = controller_busy;
assign ack_error = controller_ack_err;
assign rx_data = controller_rx;

// ------------------------------------------------------------------
// Clock divider / generator
// Produces a slower enable/phase used to drive the I2C timing
// ------------------------------------------------------------------
i2c_clk_div clk_div_u (
    .clk    (clk),
    .rst_n  (rst_n),
    .clk_en (clk_en)
);

// ------------------------------------------------------------------
// FSM / Controller
// Implements start/addr/rd/wr/stop sequence, produces control strobes
// ------------------------------------------------------------------
i2c_controller ctrl_u (
    .clk        (clk),
    .rst_n      (rst_n),

    .start_i    (start),
    .rw_i       (rw),
    .addr_i     (addr),
    .tx_data_i  (tx_data),

    .clk_en     (clk_en),

    .sda_i      (sda_in),
    .scl_i      (scl_in),

    .sda_drv_o  (sda_drv_ctrl),
    .sda_oe_o   (sda_oe_ctrl),
    .scl_drv_o  (scl_drv_ctrl),
    .scl_oe_o   (scl_oe_ctrl),

    .shift_load_o (shift_load),
    .shift_shift_o(shift_shift),
    .shift_out_i  (shift_in), // controller reads shifted-in data
    .shift_in_o   (shift_out),

    .busy_o     (controller_busy),
    .ack_err_o  (controller_ack_err),
    .rx_data_o  (controller_rx)
);

// ------------------------------------------------------------------
// Shift register
// Shifts data to/from the SDA line under clock/shift strobes
// ------------------------------------------------------------------
i2c_shift_reg shift_u (
    .clk        (clk),
    .rst_n      (rst_n),

    .load       (shift_load),
    .shift      (shift_shift),

    .din        (shift_out),
    .dout       (shift_in),

    .sda_i      (sda_in),
    .sda_drv_o  (sda_drv_shift),
    .sda_oe_o   (sda_oe_shift)
);

// Note: The `i2c_controller` and `i2c_shift_reg` both drive `sda_oe`/`sda_drv` and
// `scl_oe`/`scl_drv` in this simplified top. In a complete implementation,
// resolve conflicts by logic ORing open-drain enables (drive low if any module
// wants to pull the line low) and deciding which module supplies the data bit
// for SDA when driving. For now, the controller is the authoritative source
// of line control (it collects signals from shift reg and other units).

endmodule

// Submodules implemented in separate files: i2c_clk_div.v, i2c_shift_reg.v

// Include submodules for linter resolution
`include "i2c_controller.v"
`include "i2c_shift_reg.v"
`include "i2c_clk_div.v"
