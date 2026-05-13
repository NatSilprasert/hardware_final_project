`timescale 1ns/1ps

module tb_filter_core;
    reg         clk;
    reg         rst;
    reg [1:0]   mode;
    reg         pixel_valid;
    reg [9:0]   pixel_x;
    reg [9:0]   pixel_y;
    reg [11:0]  pixel_in;
    wire [11:0] pixel_out;

    integer edge_nonzero_count;
    integer flat_nonzero_count;
    integer x_idx;
    integer y_idx;

    filter_core #(
        .FRAME_WIDTH(12),
        .FRAME_HEIGHT(12)
    ) dut (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_in(pixel_in),
        .pixel_out(pixel_out)
    );

    always #5 clk = ~clk;

    task send_pixel;
        input [1:0]  mode_value;
        input [11:0] pixel_value;
        input [9:0]  x_value;
        input [9:0]  y_value;
        begin
            mode        = mode_value;
            pixel_valid = 1'b1;
            pixel_x     = x_value;
            pixel_y     = y_value;
            pixel_in    = pixel_value;
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk               = 1'b0;
        rst               = 1'b1;
        mode              = 2'b00;
        pixel_valid       = 1'b0;
        pixel_x           = 10'd0;
        pixel_y           = 10'd0;
        pixel_in          = 12'h000;
        edge_nonzero_count = 0;
        flat_nonzero_count = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        // raw mode
        send_pixel(2'b00, 12'hA35, 10'd0, 10'd0);
        if (pixel_out != 12'hA35) begin
            $display("ERROR: raw mode mismatch = %03h", pixel_out);
            $finish;
        end

        // grayscale mode
        send_pixel(2'b01, 12'hF00, 10'd1, 10'd0);
        if (pixel_out != 12'h333) begin
            $display("ERROR: grayscale mode mismatch = %03h", pixel_out);
            $finish;
        end

        // negative mode
        send_pixel(2'b10, 12'hA35, 10'd2, 10'd0);
        if (pixel_out != 12'h5CA) begin
            $display("ERROR: negative mode mismatch = %03h", pixel_out);
            $finish;
        end

        // reset ก่อนทดสอบ edge แบบภาพเรียบ
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;

        for (y_idx = 0; y_idx < 12; y_idx = y_idx + 1) begin
            for (x_idx = 0; x_idx < 12; x_idx = x_idx + 1) begin
                send_pixel(2'b11, 12'h000, x_idx[9:0], y_idx[9:0]);
                if (pixel_out != 12'h000) begin
                    flat_nonzero_count = flat_nonzero_count + 1;
                end
            end
        end

        if (flat_nonzero_count != 0) begin
            $display("ERROR: flat frame should not create edges count=%0d", flat_nonzero_count);
            $finish;
        end

        // reset ก่อนทดสอบ edge ที่มีรอยต่อดำ/ขาว
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        edge_nonzero_count = 0;

        for (y_idx = 0; y_idx < 12; y_idx = y_idx + 1) begin
            for (x_idx = 0; x_idx < 12; x_idx = x_idx + 1) begin
                if (x_idx < 6) begin
                    send_pixel(2'b11, 12'h000, x_idx[9:0], y_idx[9:0]);
                end else begin
                    send_pixel(2'b11, 12'hFFF, x_idx[9:0], y_idx[9:0]);
                end

                // Count only the interior region that is outside the forced-black
                // border guard used by the current Sobel implementation.
                if ((x_idx >= 4) && (x_idx < 10) &&
                    (y_idx >= 4) && (y_idx < 10) &&
                    (pixel_out != 12'h000)) begin
                    edge_nonzero_count = edge_nonzero_count + 1;
                end
            end
        end

        if (edge_nonzero_count == 0) begin
            $display("ERROR: edge mode did not detect any edge");
            $finish;
        end

        $display("PASS: tb_filter_core edge_count=%0d", edge_nonzero_count);
        $finish;
    end

endmodule
