// i2c_clk_div.v
// Simple clock divider that generates a single-cycle `clk_en` pulse
// every `DIV` system clock cycles. Parameterizable for simulation.

module i2c_clk_div #(
    parameter integer DIV = 100
)(
    input  wire clk,
    input  wire rst_n,
    output reg  clk_en
);

reg [31:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 32'd0;
        clk_en <= 1'b0;
    end else begin
        if (counter == (DIV[31:0] - 1'b1)) begin
            counter <= 32'd0;
            clk_en <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            clk_en <= 1'b0;
        end
    end
end

endmodule
