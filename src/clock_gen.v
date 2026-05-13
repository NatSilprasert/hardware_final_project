module clock_gen (
    input  wire clk_100mhz,
    input  wire rst,
    output wire clk_25mhz,
    output wire vga_clk,
    output wire cam_xclk,
    output wire locked
);
    wire clk_fb;
    wire clk_25mhz_unbuf;
    
    // MMCME2_BASE: 100 MHz in → 25 MHz out
    // VCO = 100 * 10/1 = 1000 MHz, output = 1000/40 = 25 MHz
    MMCME2_BASE #(
        .CLKIN1_PERIOD(10.0),
        .CLKFBOUT_MULT_F(10.0),
        .CLKOUT0_DIVIDE_F(40.0)
    ) u_mmcm (
        .CLKIN1(clk_100mhz),
        .RST(rst),
        .CLKFBOUT(clk_fb),
        .CLKFBIN(clk_fb),
        .CLKOUT0(clk_25mhz_unbuf),
        .LOCKED(locked),
        .PWRDWN(1'b0)
    );
    
    BUFG u_bufg (.I(clk_25mhz_unbuf), .O(clk_25mhz));
    
    // Use ODDR to drive cam_xclk on an output buffer (cleaner than fabric routing)
    ODDR #(.DDR_CLK_EDGE("OPPOSITE_EDGE")) u_oddr (
        .Q(cam_xclk), .C(clk_25mhz), .CE(1'b1),
        .D1(1'b1), .D2(1'b0), .R(1'b0), .S(1'b0)
    );
    
    assign vga_clk = clk_25mhz;
endmodule