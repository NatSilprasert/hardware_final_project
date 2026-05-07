`timescale 1ns / 1ps

module tb_ref_filter_core;

    reg        clk;
    reg        rst;
    reg  [1:0] mode;
    reg        pixel_valid;
    reg  [9:0] pixel_x;
    reg  [9:0] pixel_y;
    reg  [11:0] pixel_in;
    wire [11:0] pixel_out;

    ref_filter_core #(
        .FRAME_WIDTH(8),
        .FRAME_HEIGHT(8)
    ) uut (
        .clk        (clk),
        .rst        (rst),
        .mode       (mode),
        .pixel_valid(pixel_valid),
        .pixel_x    (pixel_x),
        .pixel_y    (pixel_y),
        .pixel_in   (pixel_in),
        .pixel_out  (pixel_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_pixel;
        input [1:0] m;
        input [11:0] pix;
        input [9:0] x;
        input [9:0] y;
        begin
            mode = m;
            pixel_in = pix;
            pixel_x = x;
            pixel_y = y;
            pixel_valid = 1'b1;
            @(posedge clk);
            pixel_valid = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        rst = 1'b1;
        mode = 2'b00;
        pixel_valid = 1'b0;
        pixel_x = 10'd0;
        pixel_y = 10'd0;
        pixel_in = 12'h000;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        send_pixel(2'b00, 12'hA35, 10'd0, 10'd0);
        send_pixel(2'b01, 12'hF00, 10'd1, 10'd0);
        send_pixel(2'b10, 12'hA35, 10'd2, 10'd0);
        send_pixel(2'b11, 12'h000, 10'd3, 10'd3);

        $display("PASS: ref_filter_core smoke");
        $finish;
    end

endmodule
