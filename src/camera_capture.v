module camera_capture #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 240,
    parameter MAX_ADDRESS  = 17'd76799
) (
    input  wire        pclk,
    input  wire        rst,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  cam_data,
    output reg  [16:0] pixel_addr,
    output reg  [11:0] pixel_data,
    output reg         pixel_valid,
    output reg         frame_start
);

    reg        byte_phase;
    reg [7:0]  first_byte;
    reg [9:0]  x_count;
    reg [8:0]  y_count;
    reg        vsync_d;

    always @(posedge pclk) begin
        if (rst) begin
            pixel_addr  <= 17'd0;
            pixel_data  <= 12'd0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            byte_phase  <= 1'b0;
            first_byte  <= 8'd0;
            x_count     <= 10'd0;
            y_count     <= 9'd0;
            vsync_d     <= 1'b0;
        end else begin
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            vsync_d     <= vsync;

            if (vsync) begin
                pixel_addr  <= 17'd0;
                byte_phase  <= 1'b0;
                x_count     <= 10'd0;
                y_count     <= 9'd0;
                frame_start <= ~vsync_d;
            end else if (href) begin
                if (!byte_phase) begin
                    first_byte <= cam_data;
                    byte_phase <= 1'b1;
                end else begin
                    byte_phase <= 1'b0;

                    if ((x_count < FRAME_WIDTH) && (y_count < FRAME_HEIGHT)) begin
                        pixel_valid <= 1'b1;
                        pixel_addr  <= (y_count * FRAME_WIDTH) + x_count;
                        pixel_data  <= {
                            first_byte[7:4],
                            {first_byte[2:0], cam_data[7]},
                            cam_data[4:1]
                        };
                    end

                    if (x_count < FRAME_WIDTH - 1) begin
                        x_count <= x_count + 1'b1;
                    end else begin
                        x_count <= 10'd0;
                        if (y_count < FRAME_HEIGHT - 1) begin
                            y_count <= y_count + 1'b1;
                        end else begin
                            y_count <= 9'd0;
                        end
                    end
                end
            end else begin
                byte_phase <= 1'b0;
            end
        end
    end

endmodule
