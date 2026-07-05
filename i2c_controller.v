// i2c_controller.v
// Top-level controller wrapper that instantiates the FSM.
// Responsibilities:
// - Provide the external controller interface used by the top module
// - Instantiate `i2c_fsm` which generates timing/control strobes

module i2c_controller (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_i,
    input  wire        rw_i,
    input  wire [6:0]  addr_i,
    input  wire [7:0]  tx_data_i,

    input  wire        clk_en,

    input  wire        sda_i,
    input  wire        scl_i,

    output wire        sda_drv_o,
    output wire        sda_oe_o,
    output wire        scl_drv_o,
    output wire        scl_oe_o,

    output wire        shift_load_o,
    output wire        shift_shift_o,
    input  wire [7:0]  shift_out_i,
    output wire [7:0]  shift_in_o,

    output wire        busy_o,
    output wire        ack_err_o,
    output wire [7:0]  rx_data_o
);

// Wire up directly to FSM implementation
i2c_fsm fsm_u (
    .clk            (clk),
    .rst_n          (rst_n),

    .start_i        (start_i),
    .rw_i           (rw_i),
    .addr_i         (addr_i),
    .tx_data_i      (tx_data_i),

    .clk_en         (clk_en),

    .shift_out_i    (shift_out_i),
    .shift_in_o     (shift_in_o),

    .shift_load_o   (shift_load_o),
    .shift_shift_o  (shift_shift_o),

    .sda_drv_o      (sda_drv_o),
    .sda_oe_o       (sda_oe_o),
    .scl_drv_o      (scl_drv_o),
    .scl_oe_o       (scl_oe_o),

    .busy_o         (busy_o),
    .ack_err_o      (ack_err_o),
    .rx_data_o      (rx_data_o)
);

endmodule

// Include FSM for linter resolution
`include "i2c_fsm.v"
