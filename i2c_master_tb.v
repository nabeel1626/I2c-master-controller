`timescale 1ns/1ps

module i2c_master_tb;
    reg         clk      = 1'b0;
    reg         rst_n    = 1'b0;
    reg         start    = 1'b0;
    reg         rw       = 1'b0;
    reg  [6:0]  addr     = 7'h50;
    reg  [7:0]  tx_data  = 8'hA5;
    wire [7:0]  rx_data;
    wire        busy;
    wire        ack_error;

    tri1        sda;
    tri1        scl;

    i2c_master dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .start     (start),
        .rw        (rw),
        .addr      (addr),
        .tx_data   (tx_data),
        .rx_data   (rx_data),
        .busy      (busy),
        .ack_error (ack_error),
        .sda       (sda),
        .scl       (scl)
    );

    initial begin
        $dumpfile("i2c_master_tb.vcd");
        $dumpvars(0, i2c_master_tb);

        // reset sequence
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        // perform a write transfer
        #20;
        do_transfer(1'b0, 7'h50, 8'hA5);

        // perform a read transfer
        #40;
        do_transfer(1'b1, 7'h50, 8'h00);

        #200;
        $display("TEST COMPLETE: busy=%b ack_error=%b rx_data=%02h", busy, ack_error, rx_data);
        #20;
        $finish;
    end

    task do_transfer;
        input op_rw;
        input [6:0] op_addr;
        input [7:0] op_data;
        begin
            @(posedge clk);
            start <= 1'b1;
            rw <= op_rw;
            addr <= op_addr;
            tx_data <= op_data;
            @(posedge clk);
            start <= 1'b0;

            wait (busy == 1'b0);
            $display("TRANSFER DONE op=%b addr=%02h data=%02h ack_error=%b rx_data=%02h",
                      op_rw, op_addr, op_data, ack_error, rx_data);
        end
    endtask

    always #5 clk = ~clk;

endmodule
