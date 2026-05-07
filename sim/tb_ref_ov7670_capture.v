`timescale 1ns / 1ps

module tb_ref_ov7670_capture;

    reg        pclk;
    reg        vsync;
    reg        href;
    reg  [7:0] d;
    wire [16:0] addr;
    wire [11:0] dout;
    wire        we;

    ref_ov7670_capture uut (
        .pclk (pclk),
        .vsync(vsync),
        .href (href),
        .d    (d),
        .addr (addr),
        .dout (dout),
        .we   (we)
    );

    initial pclk = 0;
    always #21 pclk = ~pclk;

    task send_pixel;
        input [4:0] r5;
        input [5:0] g6;
        input [4:0] b5;
        begin
            d = {r5, g6[5:3]};
            @(negedge pclk);
            d = {g6[2:0], b5};
            @(negedge pclk);
        end
    endtask

    initial begin
        vsync = 1;
        href = 0;
        d = 0;
        repeat (3) @(negedge pclk);
        vsync = 0;
        repeat (3) @(negedge pclk);
        href = 1;
        send_pixel(5'd31, 6'd63, 5'd31);
        send_pixel(5'd0, 6'd0, 5'd0);
        href = 0;
        repeat (5) @(negedge pclk);
        $finish;
    end

endmodule
