`timescale 1ns / 1ps

module tb_top;

    reg        clk = 1'b0;
    reg        btnC = 1'b1;
    reg  [1:0] sw = 2'b00;
    reg  [7:0] cam_d = 8'h00;
    reg        cam_href = 1'b0;
    reg        cam_pclk = 1'b0;
    reg        cam_vsync = 1'b0;
    wire [3:0] vgaRed;
    wire [3:0] vgaGreen;
    wire [3:0] vgaBlue;
    wire       Hsync;
    wire       Vsync;
    wire [3:0] led;
    wire       cam_pwdn;
    wire       cam_reset_n;
    wire       cam_scl;
    wire       cam_sda;
    wire       cam_xclk;

    pullup(cam_sda);

    top uut (
        .clk       (clk),
        .btnC      (btnC),
        .sw        (sw),
        .vgaRed    (vgaRed),
        .vgaGreen  (vgaGreen),
        .vgaBlue   (vgaBlue),
        .Hsync     (Hsync),
        .Vsync     (Vsync),
        .led       (led),
        .cam_d     (cam_d),
        .cam_href  (cam_href),
        .cam_pclk  (cam_pclk),
        .cam_pwdn  (cam_pwdn),
        .cam_reset_n(cam_reset_n),
        .cam_scl   (cam_scl),
        .cam_sda   (cam_sda),
        .cam_vsync (cam_vsync),
        .cam_xclk  (cam_xclk)
    );

    always #5 clk = ~clk;

    always #21 cam_pclk = ~cam_pclk;

    initial begin
        #100;
        btnC = 0;
        repeat (20) @(negedge cam_pclk);
        cam_vsync = 1;
        repeat (5) @(negedge cam_pclk);
        cam_vsync = 0;
        cam_href = 1;
        cam_d = 8'hFF;
        repeat (20) @(negedge cam_pclk);
        cam_href = 0;
        repeat (1000) @(posedge clk);
        $display("Hsync=%b Vsync=%b RGB=%h%h%h", Hsync, Vsync, vgaRed, vgaGreen, vgaBlue);
        $finish;
    end

endmodule
