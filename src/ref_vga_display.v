module ref_vga_display (
    input  wire        clk,
    input  wire        rst,
    input  wire [9:0]  hcount,
    input  wire [9:0]  vcount,
    input  wire        hactive,
    input  wire        vactive,
    input  wire [1:0]  sw,
    output wire [16:0] rd_addr,
    input  wire [11:0] rd_data,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    wire [8:0] cam_x = hcount[9:1];
    wire [7:0] cam_y = vcount[9:1];
    wire [16:0] row_offset = ({1'b0, cam_y, 8'd0}) + ({3'b0, cam_y, 6'd0});

    assign rd_addr = row_offset + {8'd0, cam_x};

    reg hactive_d1, vactive_d1;
    reg hactive_d2, vactive_d2;
    reg [9:0] hcount_d1, vcount_d1;

    initial begin
        hactive_d1 = 1'b0;
        vactive_d1 = 1'b0;
        hactive_d2 = 1'b0;
        vactive_d2 = 1'b0;
        hcount_d1 = 10'd0;
        vcount_d1 = 10'd0;
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;
    end

    always @(posedge clk) begin
        if (rst) begin
            hactive_d1 <= 1'b0;
            vactive_d1 <= 1'b0;
            hactive_d2 <= 1'b0;
            vactive_d2 <= 1'b0;
            hcount_d1   <= 10'd0;
            vcount_d1   <= 10'd0;
        end else begin
            hactive_d1 <= hactive;
            vactive_d1 <= vactive;
            hcount_d1  <= hcount;
            vcount_d1  <= vcount;
            hactive_d2 <= hactive_d1;
            vactive_d2 <= vactive_d1;
        end
    end

    wire [11:0] filtered_pixel;
    ref_filter_core u_filter (
        .clk        (clk),
        .rst        (rst),
        .mode       (sw),
        .pixel_valid (hactive_d1 & vactive_d1),
        .pixel_x    (hcount_d1),
        .pixel_y    (vcount_d1),
        .pixel_in   (rd_data),
        .pixel_out  (filtered_pixel)
    );

    always @(posedge clk) begin
        if (rst) begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end else if (hactive_d2 & vactive_d2) begin
            vga_r <= filtered_pixel[11:8];
            vga_g <= filtered_pixel[7:4];
            vga_b <= filtered_pixel[3:0];
        end else begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end

endmodule
