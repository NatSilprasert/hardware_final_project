module clock_gen (
    input  wire clk_100mhz,
    input  wire rst,
    output reg  clk_25mhz,
    output wire vga_clk,
    output wire cam_xclk
);

    reg [1:0] div_count;

    always @(posedge clk_100mhz) begin
        if (rst) begin
            div_count <= 2'd0;
            clk_25mhz <= 1'b0;
        end else begin
            // หาร 100 MHz ลงมาเป็น 25 MHz แบบง่ายด้วยตัวนับ 2 บิต
            div_count <= div_count + 1'b1;
            if (div_count == 2'd1) begin
                clk_25mhz <= ~clk_25mhz;
                div_count <= 2'd0;
            end
        end
    end

    assign vga_clk  = clk_25mhz;
    assign cam_xclk = clk_25mhz;

endmodule
