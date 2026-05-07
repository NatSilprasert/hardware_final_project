`timescale 1ns / 1ps

module tb_ref_vga_sync;

    reg        clk;
    reg        rst;
    wire       hsync;
    wire       vsync;
    wire       hactive;
    wire       vactive;
    wire [9:0] hcount;
    wire [9:0] vcount;

    ref_vga_sync uut (
        .clk     (clk),
        .rst     (rst),
        .hsync   (hsync),
        .vsync   (vsync),
        .hactive (hactive),
        .vactive (vactive),
        .hcount  (hcount),
        .vcount  (vcount)
    );

    initial clk = 0;
    always #20 clk = ~clk;

    initial begin
        rst = 1;
        #200;
        rst = 0;
        repeat (2000) @(posedge clk);
        $display("hcount=%0d vcount=%0d", hcount, vcount);
        $finish;
    end

endmodule
