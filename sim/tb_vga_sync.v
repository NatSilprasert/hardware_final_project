`timescale 1ns/1ps

module tb_vga_sync;
    reg clk;
    reg rst;

    wire        hsync;
    wire        vsync;
    wire        active_video;
    wire [9:0]  x;
    wire [9:0]  y;
    wire [8:0]  image_x;
    wire [8:0]  image_y;
    wire [16:0] frame_addr;

    integer active_count;
    integer hsync_low_count;
    integer vsync_low_count;
    integer line_count;
    integer sample_origin_ok;
    integer sample_double_ok;
    integer sample_row_ok;

    vga_sync dut (
        .pixel_clk(clk),
        .rst(rst),
        .hsync(hsync),
        .vsync(vsync),
        .active_video(active_video),
        .x(x),
        .y(y),
        .image_x(image_x),
        .image_y(image_y),
        .frame_addr(frame_addr)
    );

    always #5 clk = ~clk;

    initial begin
        clk             = 1'b0;
        rst             = 1'b1;
        active_count    = 0;
        hsync_low_count = 0;
        vsync_low_count = 0;
        line_count      = 0;
        sample_origin_ok = 0;
        sample_double_ok = 0;
        sample_row_ok    = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        // วิ่งครบ 1 frame เพื่อเช็ก timing หลัก
        repeat (800 * 525) begin
            @(posedge clk);

            if (active_video) begin
                active_count = active_count + 1;
            end

            if (!hsync) begin
                hsync_low_count = hsync_low_count + 1;
            end

            if (!vsync) begin
                vsync_low_count = vsync_low_count + 1;
            end

            if ((x == 10'd0) && (y != 10'd0)) begin
                line_count = line_count + 1;
            end

            // จุด (0,0) ควร map ไป pixel แรกของภาพ
            if ((x == 10'd0) && (y == 10'd0)) begin
                if ((image_x == 9'd0) && (image_y == 9'd0) && (frame_addr == 17'd0)) begin
                    sample_origin_ok = 1;
                end
            end

            // จุด (1,0) ต้องยังอ้างถึง pixel เดิม เพราะเป็น 2x scaling แนวนอน
            if ((x == 10'd1) && (y == 10'd0)) begin
                if ((image_x == 9'd0) && (image_y == 9'd0) && (frame_addr == 17'd0)) begin
                    sample_double_ok = 1;
                end
            end

            // จุด (2,2) ต้อง map ไป (1,1) ของภาพ
            if ((x == 10'd2) && (y == 10'd2)) begin
                if ((image_x == 9'd1) && (image_y == 9'd1) && (frame_addr == 17'd321)) begin
                    sample_row_ok = 1;
                end
            end
        end

        if (active_count != (640 * 480)) begin
            $display("ERROR: active_count mismatch = %0d", active_count);
            $finish;
        end

        if (hsync_low_count != (96 * 525)) begin
            $display("ERROR: hsync_low_count mismatch = %0d", hsync_low_count);
            $finish;
        end

        if (vsync_low_count != (2 * 800)) begin
            $display("ERROR: vsync_low_count mismatch = %0d", vsync_low_count);
            $finish;
        end

        if (line_count != 524) begin
            $display("ERROR: line_count mismatch = %0d", line_count);
            $finish;
        end

        if (!sample_origin_ok || !sample_double_ok || !sample_row_ok) begin
            $display("ERROR: scaling sample check failed o=%0d d=%0d r=%0d",
                     sample_origin_ok, sample_double_ok, sample_row_ok);
            $finish;
        end

        $display("PASS: tb_vga_sync active=%0d hlow=%0d vlow=%0d",
                 active_count, hsync_low_count, vsync_low_count);
        $finish;
    end

endmodule
