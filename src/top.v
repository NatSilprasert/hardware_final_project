//============================================================================
// Module: top
// Description: Top-level module for the OV7670 + VGA pipeline.
//              Adapted to current board pin names, but aligned with the
//              working reference architecture.
//============================================================================

module top (
    input  wire        clk,
    input  wire        btnC,
    input  wire [1:0]  sw,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
    output wire        Hsync,
    output wire        Vsync,
    output wire [3:0]  led,
    input  wire [7:0]  cam_d,
    input  wire        cam_href,
    input  wire        cam_pclk,
    output wire        cam_pwdn,
    output wire        cam_reset_n,
    output wire        cam_scl,
    inout  wire        cam_sda,
    input  wire        cam_vsync,
    output wire        cam_xclk
);

    wire        sys_rst;
    wire        clk_25mhz;
    wire        clk_24mhz;
    wire        mmcm_locked;
    wire        init_done;
    wire        cam_rst_from_init;
    wire        sccb_start;
    wire [7:0]  sccb_addr;
    wire [7:0]  sccb_data;
    wire        sccb_done;
    wire        sccb_scl;
    wire [16:0] cap_wr_addr;
    wire [11:0] cap_wr_data;
    wire        cap_wr_en;
    wire [16:0] vga_rd_addr;
    wire [11:0] vga_rd_data;
    wire [9:0]  hcount;
    wire [9:0]  vcount;
    wire        hactive;
    wire        vactive;
    wire        hsync_wire;
    wire        vsync_wire;
    wire [3:0]  vga_r;
    wire [3:0]  vga_g;
    wire [3:0]  vga_b;

    assign sys_rst     = btnC;
    assign cam_pwdn    = 1'b0;
    assign cam_reset_n = cam_rst_from_init;
    assign cam_scl     = sccb_scl;
    assign cam_xclk    = clk_25mhz;

    assign Hsync       = hsync_wire;
    assign Vsync       = vsync_wire;
    assign vgaRed      = vga_r;
    assign vgaGreen    = vga_g;
    assign vgaBlue     = vga_b;

    assign led[0] = init_done;
    assign led[1] = cam_vsync;
    assign led[2] = cam_href;
    assign led[3] = cam_pclk;

    ref_clk_wiz u_clk_wiz (
        .clk_in   (clk),
        .rst      (sys_rst),
        .clk_25mhz(clk_25mhz),
        .clk_24mhz(clk_24mhz),
        .locked   (mmcm_locked)
    );

    ref_sccb_master u_sccb_master (
        .clk   (clk),
        .rst   (sys_rst),
        .start (sccb_start),
        .addr  (sccb_addr),
        .data  (sccb_data),
        .done  (sccb_done),
        .scl   (sccb_scl),
        .sda   (cam_sda)
    );

    ref_ov7670_init u_init (
        .clk        (clk),
        .rst        (sys_rst),
        .sccb_start (sccb_start),
        .sccb_addr  (sccb_addr),
        .sccb_data  (sccb_data),
        .sccb_done  (sccb_done),
        .cam_rst_out(cam_rst_from_init),
        .init_done  (init_done)
    );

    ref_ov7670_capture u_capture (
        .pclk (cam_pclk),
        .vsync(cam_vsync),
        .href (cam_href),
        .d    (cam_d),
        .addr (cap_wr_addr),
        .dout (cap_wr_data),
        .we   (cap_wr_en)
    );

    ref_frame_buffer u_frame_buffer (
        .clk_a (cam_pclk),
        .we_a  (cap_wr_en),
        .addr_a(cap_wr_addr),
        .din_a (cap_wr_data),
        .clk_b (clk_25mhz),
        .addr_b(vga_rd_addr),
        .dout_b(vga_rd_data)
    );

    ref_vga_sync u_vga_sync (
        .clk       (clk_25mhz),
        .rst       (sys_rst),
        .hsync     (hsync_wire),
        .vsync     (vsync_wire),
        .hactive   (hactive),
        .vactive   (vactive),
        .hcount    (hcount),
        .vcount    (vcount)
    );

    ref_vga_display u_vga_display (
        .clk     (clk_25mhz),
        .rst     (sys_rst),
        .hcount  (hcount),
        .vcount  (vcount),
        .hactive (hactive),
        .vactive (vactive),
        .sw      (sw),
        .rd_addr (vga_rd_addr),
        .rd_data (vga_rd_data),
        .vga_r   (vga_r),
        .vga_g   (vga_g),
        .vga_b   (vga_b)
    );

endmodule
