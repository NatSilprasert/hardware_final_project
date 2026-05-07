module ov7670_registers #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 16
) (
    input  wire [ADDR_WIDTH-1:0] index,
    output reg  [DATA_WIDTH-1:0] reg_word,
    output wire                  valid
);

    // ตาราง register สำหรับตั้งค่า OV7670 แบบ baseline:
    // reset -> RGB444 -> QVGA/downsample
    localparam REG_COUNT = 20;

    assign valid = (index < REG_COUNT);

    always @(*) begin
        reg_word = 16'hFFFF;

        case (index)
            5'd0:  reg_word = 16'h1280; // COM7  : reset register
            5'd1:  reg_word = 16'h1214; // COM7  : QVGA + RGB output
            5'd2:  reg_word = 16'h1101; // CLKRC : แบ่ง clock ภายในแบบง่าย
            5'd3:  reg_word = 16'h0C0C; // COM3  : enable scaling + DCW
            5'd4:  reg_word = 16'h3E1A; // COM14 : manual scaling + DCW/PCLK + divide by 4
            5'd5:  reg_word = 16'h40D0; // COM15 : full output range, RGB444 enabled path
            5'd6:  reg_word = 16'h3A04; // TSLB  : ใช้ลำดับข้อมูลมาตรฐานสำหรับ RGB path
            5'd7:  reg_word = 16'h8C03; // RGB444: enable + word format = RG Bx
            5'd8:  reg_word = 16'h1716; // HSTART: ค่าหน้าต่างแนวนอนชุดที่นิยมใช้
            5'd9:  reg_word = 16'h1804; // HSTOP
            5'd10: reg_word = 16'h1902; // VSTRT
            5'd11: reg_word = 16'h1A7A; // VSTOP
            5'd12: reg_word = 16'h3210; // HREF  : fine tuning ขอบภาพ
            5'd13: reg_word = 16'h030A; // VREF  : fine tuning ขอบภาพ
            5'd14: reg_word = 16'h703A; // SCALING_XSC
            5'd15: reg_word = 16'h7135; // SCALING_YSC
            5'd16: reg_word = 16'h7211; // SCALING_DCWCTR : downsample by 2
            5'd17: reg_word = 16'h73F1; // SCALING_PCLK_DIV
            5'd18: reg_word = 16'hA202; // SCALING_PCLK_DELAY
            5'd19: reg_word = 16'h1500; // COM10 : ใช้ PCLK ปกติ
            default: reg_word = 16'hFFFF;
        endcase
    end

endmodule
