module vga_sync #(
    parameter H_VISIBLE      = 640,
    parameter H_FRONT_PORCH  = 16,
    parameter H_SYNC_PULSE   = 96,
    parameter H_BACK_PORCH   = 48,
    parameter V_VISIBLE      = 480,
    parameter V_FRONT_PORCH  = 10,
    parameter V_SYNC_PULSE   = 2,
    parameter V_BACK_PORCH   = 33,
    parameter IMAGE_WIDTH    = 320,
    parameter IMAGE_HEIGHT   = 240,
    parameter ADDR_WIDTH     = 17
) (
    input  wire                  pixel_clk,
    input  wire                  rst,
    output reg                   hsync,
    output reg                   vsync,
    output reg                   active_video,
    output reg  [9:0]            x,
    output reg  [9:0]            y,
    output reg  [8:0]            image_x,
    output reg  [8:0]            image_y,
    output reg  [ADDR_WIDTH-1:0] frame_addr
);

    localparam H_TOTAL = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
    localparam V_TOTAL = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge pixel_clk) begin
        if (rst) begin
            h_count      <= 10'd0;
            v_count      <= 10'd0;
            hsync        <= 1'b1;
            vsync        <= 1'b1;
            active_video <= 1'b0;
            x            <= 10'd0;
            y            <= 10'd0;
            image_x      <= 9'd0;
            image_y      <= 9'd0;
            frame_addr   <= {ADDR_WIDTH{1'b0}};
        end else begin
            // ตัวนับหลักของ VGA วิ่งครบทั้ง line และ frame
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end

            // sync ของ VGA เป็น active-low
            hsync <= ~((h_count >= (H_VISIBLE + H_FRONT_PORCH)) &&
                       (h_count <  (H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE)));
            vsync <= ~((v_count >= (V_VISIBLE + V_FRONT_PORCH)) &&
                       (v_count <  (V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE)));

            // active video มีเฉพาะพื้นที่ 640x480 ด้านใน
            active_video <= (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
            x <= h_count;
            y <= v_count;

            // ทำ pixel doubling: จอ 640x480 -> ภาพ 320x240
            if ((h_count < H_VISIBLE) && (v_count < V_VISIBLE)) begin
                image_x <= h_count[9:1];
                image_y <= v_count[9:1];

                if ((h_count[9:1] < IMAGE_WIDTH) && (v_count[9:1] < IMAGE_HEIGHT)) begin
                    frame_addr <= (v_count[9:1] * IMAGE_WIDTH) + h_count[9:1];
                end else begin
                    frame_addr <= {ADDR_WIDTH{1'b0}};
                end
            end else begin
                image_x    <= 9'd0;
                image_y    <= 9'd0;
                frame_addr <= {ADDR_WIDTH{1'b0}};
            end
        end
    end

endmodule
