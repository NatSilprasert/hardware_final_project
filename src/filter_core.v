module filter_core #(
    parameter FRAME_WIDTH  = 640,
    parameter FRAME_HEIGHT = 480
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  mode,
    input  wire        pixel_valid,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [11:0] pixel_in,
    output reg  [11:0] pixel_out
);

    // Line buffers for 3x3 convolution window (2 previous rows)
    reg [3:0] gray_line_1 [0:FRAME_WIDTH-1];
    reg [3:0] gray_line_2 [0:FRAME_WIDTH-1];

    // 3x3 window registers
    //   win00 win01 win02   ← row from 2 lines ago
    //   win10 win11 win12   ← row from 1 line ago
    //   win20 win21 win22   ← current row
    reg [3:0] win00, win01, win02;
    reg [3:0] win10, win11, win12;
    reg [3:0] win20, win21, win22;

    reg [3:0] gray_now;
    reg [3:0] old_line_1;
    reg [3:0] old_line_2;

    // Use signed reg instead of integer for proper synthesis
    reg signed [7:0] gx_val, gy_val;
    reg [7:0] abs_gx, abs_gy;
    reg [8:0] edge_mag;  // |Gx| + |Gy|, up to 255+255
    reg [3:0] edge_gray;

    // Grayscale conversion: (R + 2*G + B) / 4
    function [3:0] rgb444_to_gray4;
        input [11:0] rgb;
        reg [5:0] gray_sum;
        begin
            gray_sum = {2'b00, rgb[11:8]} + {1'b0, rgb[7:4], 1'b0} + {2'b00, rgb[3:0]};
            rgb444_to_gray4 = gray_sum[5:2];
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            win00 <= 4'd0; win01 <= 4'd0; win02 <= 4'd0;
            win10 <= 4'd0; win11 <= 4'd0; win12 <= 4'd0;
            win20 <= 4'd0; win21 <= 4'd0; win22 <= 4'd0;
            gray_now   <= 4'd0;
            old_line_1 <= 4'd0;
            old_line_2 <= 4'd0;
            edge_gray  <= 4'd0;
            pixel_out  <= 12'h000;
        end else begin
            if (pixel_valid) begin
                // Convert current pixel to grayscale
                gray_now   = rgb444_to_gray4(pixel_in);
                old_line_1 = gray_line_1[pixel_x];
                old_line_2 = gray_line_2[pixel_x];

                // Update line buffers: shift rows down
                gray_line_2[pixel_x] <= old_line_1;
                gray_line_1[pixel_x] <= gray_now;

                // Shift 3x3 window left, insert new column from line buffers
                win00 <= win01;  win01 <= win02;  win02 <= old_line_2;
                win10 <= win11;  win11 <= win12;  win12 <= old_line_1;
                win20 <= win21;  win21 <= win22;  win22 <= gray_now;

                case (mode)
                    2'b00: begin
                        // Raw passthrough
                        pixel_out <= pixel_in;
                    end

                    2'b01: begin
                        // Grayscale
                        pixel_out <= {gray_now, gray_now, gray_now};
                    end

                    2'b10: begin
                        // Negative / Invert
                        pixel_out <= {4'hF - pixel_in[11:8],
                                      4'hF - pixel_in[7:4],
                                      4'hF - pixel_in[3:0]};
                    end

                    2'b11: begin
                        // Sobel edge detection
                        // Border pixels → black to avoid window artifacts
                        if ((pixel_x < 10'd4) || (pixel_y < 10'd4) ||
                            (pixel_x >= FRAME_WIDTH - 2) || (pixel_y >= FRAME_HEIGHT - 2)) begin
                            edge_gray = 4'd0;
                        end else begin
                            // Sobel Gx kernel:        Sobel Gy kernel:
                            //  -1  0 +1               -1 -2 -1
                            //  -2  0 +2                0  0  0
                            //  -1  0 +1               +1 +2 +1
                            gx_val = ({4'b0, win02} + {3'b0, win12, 1'b0} + {4'b0, win22})
                                   - ({4'b0, win00} + {3'b0, win10, 1'b0} + {4'b0, win20});

                            gy_val = ({4'b0, win20} + {3'b0, win21, 1'b0} + {4'b0, win22})
                                   - ({4'b0, win00} + {3'b0, win01, 1'b0} + {4'b0, win02});

                            // Absolute values
                            abs_gx = gx_val[7] ? (~gx_val + 1'b1) : gx_val;
                            abs_gy = gy_val[7] ? (~gy_val + 1'b1) : gy_val;

                            // Edge magnitude = |Gx| + |Gy| (approximation of sqrt)
                            edge_mag = {1'b0, abs_gx} + {1'b0, abs_gy};

                            // Multi-level thresholding for smooth edge rendering
                            if (edge_mag > 9'd48)
                                edge_gray = 4'hF;  // strong edge → white
                            else if (edge_mag > 9'd32)
                                edge_gray = 4'hC;
                            else if (edge_mag > 9'd20)
                                edge_gray = 4'h9;
                            else if (edge_mag > 9'd12)
                                edge_gray = 4'h6;
                            else if (edge_mag > 9'd6)
                                edge_gray = 4'h3;
                            else
                                edge_gray = 4'h0;  // no edge → black
                        end

                        pixel_out <= {edge_gray, edge_gray, edge_gray};
                    end
                endcase
            end else begin
                pixel_out <= 12'h000;
            end
        end
    end

endmodule
