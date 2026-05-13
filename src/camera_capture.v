// Camera capture with BRAM test pattern mode.
// When test_mode=1, writes a computed gradient to BRAM using camera timing.
// This tests the BRAM dual-clock path without depending on camera pixel data.
module camera_capture #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 240
) (
    input  wire        pclk,
    input  wire        rst,
    input  wire        test_mode,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  cam_data,
    output wire [16:0] pixel_addr,
    output reg  [11:0] pixel_data,
    output reg         pixel_valid,
    output reg         frame_start
);
    reg [15:0] d_latch;
    reg [1:0]  wr_hold;
    reg [9:0]  x_count;
    reg [8:0]  y_count;
    reg        vsync_d;

    assign pixel_addr = y_count * FRAME_WIDTH + x_count;

    // Test pattern: red/green gradient based on x/y position
    wire [11:0] test_pixel = {x_count[3:0], y_count[3:0], 4'hA};

    always @(posedge pclk) begin
        if (rst) begin
            pixel_data  <= 12'd0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            d_latch     <= 16'd0;
            wr_hold     <= 2'd0;
            x_count     <= 10'd0;
            y_count     <= 9'd0;
            vsync_d     <= 1'b0;
        end else begin
            frame_start <= 1'b0;
            vsync_d     <= vsync;

            if (vsync) begin
                x_count     <= 10'd0;
                y_count     <= 9'd0;
                wr_hold     <= 2'd0;
                pixel_valid <= 1'b0;
                if (~vsync_d) frame_start <= 1'b1;
            end else begin
                // Shift in each byte (reference design pattern)
                d_latch <= {d_latch[7:0], cam_data};

                // Toggle: href starts a byte-pair, alternates each cycle
                wr_hold <= {wr_hold[0], (href & ~wr_hold[0])};

                // pixel_valid delayed by 1 cycle from wr_hold[1]
                pixel_valid <= wr_hold[1];

                if (wr_hold[1]) begin
                    if (test_mode) begin
                        // BRAM test: write gradient pattern instead of camera data
                        pixel_data <= test_pixel;
                    end else begin
                        // Normal: RGB565 → RGB444
                        pixel_data <= {
                            d_latch[15:12],  // R: top 4 of 5
                            d_latch[10:7],   // G: top 4 of 6
                            d_latch[4:1]     // B: top 4 of 5
                        };
                    end

                    if (x_count < FRAME_WIDTH - 1) begin
                        x_count <= x_count + 1'b1;
                    end else begin
                        x_count <= 10'd0;
                        if (y_count < FRAME_HEIGHT - 1)
                            y_count <= y_count + 1'b1;
                        else
                            y_count <= 9'd0;
                    end
                end
            end
        end
    end
endmodule
