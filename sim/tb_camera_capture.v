`timescale 1ns/1ps

module tb_camera_capture;
    reg        pclk;
    reg        rst;
    reg        vsync;
    reg        href;
    reg [7:0]  cam_data;
    wire [16:0] pixel_addr;
    wire [11:0] pixel_data;
    wire        pixel_valid;
    wire        frame_start;

    camera_capture dut (
        .pclk(pclk),
        .rst(rst),
        .vsync(vsync),
        .href(href),
        .cam_data(cam_data),
        .pixel_addr(pixel_addr),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_start(frame_start)
    );

    always #5 pclk = ~pclk;

    task send_byte;
        input [7:0] value;
        begin
            cam_data = value;
            @(posedge pclk);
        end
    endtask

    initial begin
        pclk     = 1'b0;
        rst      = 1'b1;
        vsync    = 1'b0;
        href     = 1'b0;
        cam_data = 8'h00;

        repeat (4) @(posedge pclk);
        rst = 1'b0;

        // สร้างขอบขึ้นของ VSYNC เพื่อเริ่ม frame ใหม่
        @(posedge pclk);
        vsync = 1'b1;
        @(posedge pclk);
        vsync = 1'b0;

        if (!frame_start) begin
            $display("ERROR: frame_start was not asserted");
            $finish;
        end

        href = 1'b1;

        // pixel 0: RGB565 = F800 -> RGB444 = F00
        send_byte(8'hF8);
        send_byte(8'h00);
        @(negedge pclk);
        if (!pixel_valid || pixel_addr != 17'd0 || pixel_data != 12'hF00) begin
            $display("ERROR: pixel 0 mismatch addr=%0d data=%03h valid=%0b", pixel_addr, pixel_data, pixel_valid);
            $finish;
        end

        // pixel 1: RGB565 = 07E0 -> RGB444 = 0F0
        send_byte(8'h07);
        send_byte(8'hE0);
        @(negedge pclk);
        if (!pixel_valid || pixel_addr != 17'd1 || pixel_data != 12'h0F0) begin
            $display("ERROR: pixel 1 mismatch addr=%0d data=%03h valid=%0b", pixel_addr, pixel_data, pixel_valid);
            $finish;
        end

        href = 1'b0;
        @(posedge pclk);

        $display("PASS: tb_camera_capture");
        $finish;
    end

endmodule
