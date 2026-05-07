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

    wire [4:0] r5;
    wire [5:0] g6;
    wire [4:0] b5;

    assign r5 = first_byte[7:3];
    assign g6 = {first_byte[2:0], cam_data[7:5]};
    assign b5 = cam_data[4:0];

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
            // ค่า pulse ให้เป็น 1 แค่ clock เดียว
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            vsync_d     <= vsync;

            // ใช้ขอบขึ้นของ VSYNC เป็นจุดเริ่ม frame ใหม่
            if (~vsync_d && vsync) begin
                pixel_addr  <= 17'd0;
                byte_phase  <= 1'b0;
                x_count     <= 10'd0;
                y_count     <= 9'd0;
                frame_start <= 1'b1;
            end else if (href) begin
                // ตอน HREF เป็น 1 แปลว่าข้อมูลในแถวนี้ valid
                if (~byte_phase) begin
                    first_byte <= cam_data;
                    byte_phase <= 1'b1;
                end else begin
                    byte_phase  <= 1'b0;
                    pixel_valid <= 1'b1;

                    // แปลง RGB565 -> RGB444 เพื่อลดการใช้ BRAM
                    pixel_data[11:8] <= r5[4:1];
                    pixel_data[7:4]  <= g6[5:2];
                    pixel_data[3:0]  <= b5[4:1];

                    pixel_addr <= (y_count * FRAME_WIDTH) + x_count;

                    if (x_count == FRAME_WIDTH - 1) begin
                        x_count <= 10'd0;
                        if (y_count != FRAME_HEIGHT - 1) begin
                            y_count <= y_count + 1'b1;
                        end
                    end else begin
                        x_count <= x_count + 1'b1;
                    end
                end
            end else begin
                // ถ้าออกจาก HREF กลาง pixel ให้เริ่มจับ byte ใหม่ในแถวถัดไป
                byte_phase <= 1'b0;
                x_count    <= 10'd0;
            end
        end
    end

endmodule
