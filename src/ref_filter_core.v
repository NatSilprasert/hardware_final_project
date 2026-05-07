module ref_filter_core #(
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

    reg [3:0] gray_line_1 [0:FRAME_WIDTH-1];
    reg [3:0] gray_line_2 [0:FRAME_WIDTH-1];

    reg [3:0] win00;
    reg [3:0] win01;
    reg [3:0] win02;
    reg [3:0] win10;
    reg [3:0] win11;
    reg [3:0] win12;
    reg [3:0] win20;
    reg [3:0] win21;
    reg [3:0] win22;

    reg [3:0] gray_now;
    reg [3:0] old_line_1;
    reg [3:0] old_line_2;
    reg [3:0] edge_gray;

    integer gx_value;
    integer gy_value;
    integer edge_strength;
    integer i;

    function [3:0] rgb444_to_gray4;
        input [11:0] rgb;
        reg [5:0] gray_sum;
        begin
            gray_sum = {2'b00, rgb[11:8]} + {1'b0, rgb[7:4], 1'b0} + {2'b00, rgb[3:0]};
            rgb444_to_gray4 = gray_sum[5:2];
        end
    endfunction

    function integer abs_int;
        input integer value;
        begin
            if (value < 0) begin
                abs_int = -value;
            end else begin
                abs_int = value;
            end
        end
    endfunction

    initial begin
        pixel_out = 12'h000;
        gray_now = 4'h0;
        old_line_1 = 4'h0;
        old_line_2 = 4'h0;
        edge_gray = 4'h0;
        win00 = 4'h0;
        win01 = 4'h0;
        win02 = 4'h0;
        win10 = 4'h0;
        win11 = 4'h0;
        win12 = 4'h0;
        win20 = 4'h0;
        win21 = 4'h0;
        win22 = 4'h0;
        for (i = 0; i < FRAME_WIDTH; i = i + 1) begin
            gray_line_1[i] = 4'h0;
            gray_line_2[i] = 4'h0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            win00      <= 4'd0;
            win01      <= 4'd0;
            win02      <= 4'd0;
            win10      <= 4'd0;
            win11      <= 4'd0;
            win12      <= 4'd0;
            win20      <= 4'd0;
            win21      <= 4'd0;
            win22      <= 4'd0;
            gray_now   <= 4'd0;
            old_line_1 <= 4'd0;
            old_line_2 <= 4'd0;
            edge_gray  <= 4'd0;
            pixel_out  <= 12'h000;
        end else begin
            if (pixel_valid) begin
                gray_now   = rgb444_to_gray4(pixel_in);
                old_line_1 = gray_line_1[pixel_x];
                old_line_2 = gray_line_2[pixel_x];

                gray_line_2[pixel_x] <= old_line_1;
                gray_line_1[pixel_x] <= gray_now;

                win00 <= win01;
                win01 <= win02;
                win02 <= old_line_2;

                win10 <= win11;
                win11 <= win12;
                win12 <= old_line_1;

                win20 <= win21;
                win21 <= win22;
                win22 <= gray_now;

                case (mode)
                    2'b00: begin
                        pixel_out <= pixel_in;
                    end

                    2'b01: begin
                        pixel_out <= {gray_now, gray_now, gray_now};
                    end

                    2'b10: begin
                        pixel_out <= {4'hF - pixel_in[11:8],
                                      4'hF - pixel_in[7:4],
                                      4'hF - pixel_in[3:0]};
                    end

                    default: begin
                        if ((pixel_x < 10'd2) || (pixel_y < 10'd2) ||
                            (pixel_x >= FRAME_WIDTH - 1) || (pixel_y >= FRAME_HEIGHT - 1)) begin
                            edge_gray = 4'd0;
                        end else begin
                            gx_value = (win02 + (win12 << 1) + win22) -
                                       (win00 + (win10 << 1) + win20);
                            gy_value = (win20 + (win21 << 1) + win22) -
                                       (win00 + (win01 << 1) + win02);

                            edge_strength = abs_int(gx_value) + abs_int(gy_value);

                            if (edge_strength > 60) begin
                                edge_gray = 4'hF;
                            end else if (edge_strength > 40) begin
                                edge_gray = 4'hC;
                            end else if (edge_strength > 24) begin
                                edge_gray = 4'h8;
                            end else if (edge_strength > 12) begin
                                edge_gray = 4'h4;
                            end else begin
                                edge_gray = 4'h0;
                            end
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
