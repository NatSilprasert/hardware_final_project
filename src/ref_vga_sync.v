//============================================================================
// Module: ref_vga_sync
// Description: VGA sync signal generator for 640x480 @ 60Hz.
//============================================================================

module ref_vga_sync #(
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
    input  wire                  clk,
    input  wire                  rst,
    output wire                  hsync,
    output wire                  vsync,
    output wire                  hactive,
    output wire                  vactive,
    output reg  [9:0]            hcount,
    output reg  [9:0]            vcount
);

    localparam H_TOTAL = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;
    localparam V_TOTAL = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

    localparam H_SYNC_START = H_VISIBLE + H_FRONT_PORCH;
    localparam H_SYNC_END   = H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE;
    localparam V_SYNC_START = V_VISIBLE + V_FRONT_PORCH;
    localparam V_SYNC_END   = V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE;

    initial begin
        hcount = 10'd0;
        vcount = 10'd0;
    end

    always @(posedge clk) begin
        if (rst) begin
            hcount <= 10'd0;
        end else if (hcount == H_TOTAL - 1) begin
            hcount <= 10'd0;
        end else begin
            hcount <= hcount + 10'd1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            vcount <= 10'd0;
        end else if (hcount == H_TOTAL - 1) begin
            if (vcount == V_TOTAL - 1)
                vcount <= 10'd0;
            else
                vcount <= vcount + 10'd1;
        end
    end

    assign hsync = ~((hcount >= H_SYNC_START) && (hcount < H_SYNC_END));
    assign vsync = ~((vcount >= V_SYNC_START) && (vcount < V_SYNC_END));
    assign hactive = (hcount < H_VISIBLE);
    assign vactive = (vcount < V_VISIBLE);

endmodule
