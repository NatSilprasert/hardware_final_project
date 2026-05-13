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

    wire        vga_clk;
    wire        mmcm_locked;
    wire        config_done;
    wire        sccb_busy;
    wire [7:0]  sccb_index;
    wire [16:0] cam_pixel_addr;
    wire [11:0] cam_pixel_data;
    wire        cam_pixel_valid;
    wire        cam_frame_start;
    wire [16:0] vga_frame_addr;
    wire [11:0] fb_pixel_data;
    wire [11:0] filtered_pixel_data;
    wire        vga_active_raw;
    wire        vga_hsync_raw;
    wire        vga_vsync_raw;
    wire [9:0]  vga_x;
    wire [9:0]  vga_y;
    wire [8:0]  image_x;
    wire [8:0]  image_y;

    wire sys_rst = btnC | ~mmcm_locked;

    reg         vga_active_d1;
    reg         vga_hsync_d1;
    reg         vga_vsync_d1;
    reg         vga_active_d2;
    reg         vga_hsync_d2;
    reg         vga_vsync_d2;
    reg [9:0]   vga_x_d1;
    reg [9:0]   vga_y_d1;
    reg [11:0]  vga_rgb_d;
    reg         frame_seen_latched;

    assign cam_pwdn     = 1'b0;
    assign cam_reset_n  = 1'b1;
    assign Hsync        = vga_hsync_d2;
    assign Vsync        = vga_vsync_d2;
    assign vgaRed       = vga_rgb_d[11:8];
    assign vgaGreen     = vga_rgb_d[7:4];
    assign vgaBlue      = vga_rgb_d[3:0];

    assign led[0] = config_done;
    assign led[1] = frame_seen_latched;
    assign led[2] = sw[0];
    assign led[3] = sw[1];

    // ----- Clock generator (MMCM) -----
    clock_gen u_clock_gen (
        .clk_100mhz(clk),
        .rst(btnC),
        .clk_25mhz(),
        .vga_clk(vga_clk),
        .cam_xclk(cam_xclk),
        .locked(mmcm_locked)
    );

    // ----- SCCB master -----
    sccb_master u_sccb_master (
        .clk(clk),
        .rst(sys_rst),
        .scl(cam_scl),
        .sda(cam_sda),
        .config_done(config_done),
        .busy(sccb_busy),
        .current_index(sccb_index)
    );

    camera_capture u_camera_capture (
        .pclk(cam_pclk),
        .rst(sys_rst),
        .test_mode(1'b0),
        .vsync(cam_vsync),
        .href(cam_href),
        .cam_data(cam_d),
        .pixel_addr(cam_pixel_addr),
        .pixel_data(cam_pixel_data),
        .pixel_valid(cam_pixel_valid),
        .frame_start(cam_frame_start)
    );

    // ----- Frame buffer -----
    frame_buffer u_frame_buffer (
        .wr_clk(cam_pclk),
        .wr_en(cam_pixel_valid),
        .wr_addr(cam_pixel_addr),
        .wr_data(cam_pixel_data),
        .rd_clk(vga_clk),
        .rd_addr(vga_frame_addr),
        .rd_data(fb_pixel_data)
    );

    // ----- VGA timing -----
    vga_sync u_vga_sync (
        .pixel_clk(vga_clk),
        .rst(sys_rst),
        .hsync(vga_hsync_raw),
        .vsync(vga_vsync_raw),
        .active_video(vga_active_raw),
        .x(vga_x),
        .y(vga_y),
        .image_x(image_x),
        .image_y(image_y),
        .frame_addr(vga_frame_addr)
    );

    // ----- Filter core -----
    filter_core u_filter_core (
        .clk(vga_clk),
        .rst(sys_rst),
        .mode(sw),
        .pixel_valid(vga_active_d1),
        .pixel_x(vga_x_d1),
        .pixel_y(vga_y_d1),
        .pixel_in(fb_pixel_data),
        .pixel_out(filtered_pixel_data)
    );

    // ----- Frame-seen latch (LED debug) -----
    always @(posedge cam_pclk) begin
        if (sys_rst)
            frame_seen_latched <= 1'b0;
        else if (cam_frame_start)
            frame_seen_latched <= 1'b1;
    end

    // ----- VGA output pipeline -----
    // All modes now go through BRAM (no more VGA-direct bypass)
    always @(posedge vga_clk) begin
        if (sys_rst) begin
            vga_active_d1 <= 1'b0;
            vga_hsync_d1  <= 1'b1;
            vga_vsync_d1  <= 1'b1;
            vga_active_d2 <= 1'b0;
            vga_hsync_d2  <= 1'b1;
            vga_vsync_d2  <= 1'b1;
            vga_x_d1      <= 10'd0;
            vga_y_d1      <= 10'd0;
            vga_rgb_d     <= 12'h000;
        end else begin
            // Stage 1: BRAM read latency
            vga_active_d1 <= vga_active_raw;
            vga_hsync_d1  <= vga_hsync_raw;
            vga_vsync_d1  <= vga_vsync_raw;
            vga_x_d1      <= vga_x;
            vga_y_d1      <= vga_y;

            // Stage 2: filter latency
            vga_active_d2 <= vga_active_d1;
            vga_hsync_d2  <= vga_hsync_d1;
            vga_vsync_d2  <= vga_vsync_d1;

            if (vga_active_d2)
                vga_rgb_d <= filtered_pixel_data;
            else
                vga_rgb_d <= 12'h000;
        end
    end

endmodule
