// i2c_fsm.v
// A simplified I2C master finite-state machine.
// This FSM is intentionally minimal and designed to demonstrate
// sequencing for a single address + one data byte transfer.
// It operates only when `clk_en` pulses (driven by the clock divider).

module i2c_fsm (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_i,    // start transfer request
    input  wire        rw_i,       // 0 = write, 1 = read
    input  wire [6:0]  addr_i,
    input  wire [7:0]  tx_data_i,

    input  wire        clk_en,     // timing enable (from clk divider)

    input  wire [7:0]  shift_out_i, // data shifted in from shift_reg
    output reg  [7:0]  shift_in_o,  // data to load into shift_reg

    output reg         shift_load_o,
    output reg         shift_shift_o,

    output reg         sda_drv_o,
    output reg         sda_oe_o,
    output reg         scl_drv_o,
    output reg         scl_oe_o,

    output reg         busy_o,
    output reg         ack_err_o,
    output reg [7:0]   rx_data_o
    // start/stop requests removed (handled internally by FSM/controller)
);

// States
localparam IDLE      = 3'd0;
localparam ADDR_PH   = 3'd1; // address phase shifting
localparam ACK_ADDR  = 3'd2;
localparam DATA_PH   = 3'd3; // data byte phase
localparam ACK_DATA  = 3'd4;
localparam STOP_PH   = 3'd5;
localparam DONE      = 3'd6;

reg [2:0] state;
reg [3:0] bit_cnt; // counts 0..7

// Edge-sensitive operations: run FSM transitions only when clk_en pulses.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        bit_cnt <= 4'd0;
        shift_load_o <= 1'b0;
        shift_shift_o <= 1'b0;
        shift_in_o <= 8'h00;
        sda_drv_o <= 1'b0;
        sda_oe_o <= 1'b0;
        scl_drv_o <= 1'b0;
        scl_oe_o <= 1'b0;
        busy_o <= 1'b0;
        ack_err_o <= 1'b0;
        rx_data_o <= 8'h00;
        // start/stop signals removed
    end else begin
        // default single-cycle pulse clears
        shift_load_o <= 1'b0;
        shift_shift_o <= 1'b0;

        if (clk_en) begin
            case (state)
                IDLE: begin
                    busy_o <= 1'b0;
                    ack_err_o <= 1'b0;
                    if (start_i) begin
                        // prepare address byte: [addr(7:1), R/W]
                        shift_in_o <= {addr_i, rw_i};
                        shift_load_o <= 1'b1; // load address into shift reg
                        bit_cnt <= 4'd7;
                        busy_o <= 1'b1;
                        state <= ADDR_PH;
                    end
                end

                ADDR_PH: begin
                    // shift one bit per clk_en pulse
                    shift_shift_o <= 1'b1;
                    if (bit_cnt == 0) begin
                        state <= ACK_ADDR;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ACK_ADDR: begin
                    // sample ACK bit from shift_out_i LSB (shift_reg provides sampled bits)
                    // for simplicity assume the ACK bit is available in shift_out_i[0]
                    if (shift_out_i[0] == 1'b1) begin
                        // NACK
                        ack_err_o <= 1'b1;
                        state <= STOP_PH;
                    end else begin
                        // ACK received
                        if (rw_i == 1'b0) begin
                            // write: load TX data and shift
                            shift_in_o <= tx_data_i;
                            shift_load_o <= 1'b1;
                            bit_cnt <= 4'd7;
                            state <= DATA_PH;
                        end else begin
                            // read: load zeros for the shift reg so slave drives SDA
                            shift_in_o <= 8'h00;
                            shift_load_o <= 1'b1;
                            bit_cnt <= 4'd7;
                            state <= DATA_PH;
                        end
                    end
                end

                DATA_PH: begin
                    shift_shift_o <= 1'b1;
                    if (bit_cnt == 0) begin
                        state <= ACK_DATA;
                        // capture received byte from shift_out_i
                        rx_data_o <= shift_out_i;
                    end else begin
                        bit_cnt <= bit_cnt - 1'b1;
                    end
                end

                ACK_DATA: begin
                    // sample ACK/NACK from slave after data phase
                    if (shift_out_i[0] == 1'b1) begin
                        ack_err_o <= 1'b1;
                    end
                    state <= STOP_PH;
                end

                STOP_PH: begin
                    // request STOP condition (handled by controller)
                    state <= DONE;
                end

                DONE: begin
                    busy_o <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
end

endmodule
