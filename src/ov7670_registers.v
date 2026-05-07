module ov7670_registers #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
) (
    input  wire [ADDR_WIDTH-1:0] index,
    output reg  [DATA_WIDTH-1:0] reg_word,
    output wire                  valid
);

    // Baseline OV7670 setup: reset -> RGB565 -> QVGA 320x240.
    // Includes the color/AGC/AWB registers that are commonly needed for a
    // stable RGB stream; a too-short table often gives magenta/yellow noise.
    localparam REG_COUNT = 52;

    assign valid = (index < REG_COUNT);

    always @(*) begin
        reg_word = 16'hFFFF;

        case (index)
            6'd0:  reg_word = 16'h1280; // COM7   : reset register
            6'd1:  reg_word = 16'h1214; // COM7   : QVGA + RGB output
            6'd2:  reg_word = 16'h1101; // CLKRC  : internal clock divide
            6'd3:  reg_word = 16'h0C04; // COM3   : enable DCW for QVGA
            6'd4:  reg_word = 16'h3E19; // COM14  : manual scaling + PCLK divide
            6'd5:  reg_word = 16'h7211; // DCWCTR : downsample by 2
            6'd6:  reg_word = 16'h73F1; // PCLK_DIV
            6'd7:  reg_word = 16'hA202; // PCLK_DELAY
            6'd8:  reg_word = 16'h40D0; // COM15  : RGB565 + full output range
            6'd9:  reg_word = 16'h3A04; // TSLB   : RGB565 byte order
            6'd10: reg_word = 16'h8C00; // RGB444 : disable RGB444 mode
            6'd11: reg_word = 16'h1500; // COM10  : normal PCLK/VSYNC/HREF polarity

            // Active image window used by the common QVGA profile.
            6'd12: reg_word = 16'h1716; // HSTART
            6'd13: reg_word = 16'h1804; // HSTOP
            6'd14: reg_word = 16'h3280; // HREF edge offset
            6'd15: reg_word = 16'h1902; // VSTART
            6'd16: reg_word = 16'h1A7A; // VSTOP
            6'd17: reg_word = 16'h030A; // VREF edge offset
            6'd18: reg_word = 16'h703A; // SCALING_XSC
            6'd19: reg_word = 16'h7135; // SCALING_YSC

            // Color matrix and automatic controls for sane RGB output.
            6'd20: reg_word = 16'h1307; // COM8   : AGC + AWB + AEC
            6'd21: reg_word = 16'h1418; // COM9   : AGC gain ceiling
            6'd22: reg_word = 16'h4FB3; // MTX1
            6'd23: reg_word = 16'h50B3; // MTX2
            6'd24: reg_word = 16'h5100; // MTX3
            6'd25: reg_word = 16'h523D; // MTX4
            6'd26: reg_word = 16'h53A7; // MTX5
            6'd27: reg_word = 16'h54E4; // MTX6
            6'd28: reg_word = 16'h589E; // MTXS
            6'd29: reg_word = 16'h3DC0; // COM13  : gamma + UV saturation
            6'd30: reg_word = 16'h6900; // GFIX
            6'd31: reg_word = 16'h6B4A; // DBLV   : PLL bypass, stable clock profile
            6'd32: reg_word = 16'hA703; // AWB control
            6'd33: reg_word = 16'hA8B0; // AWB control
            6'd34: reg_word = 16'hA9B0; // AWB control
            6'd35: reg_word = 16'hAA92; // AWB control
            6'd36: reg_word = 16'hAB21; // AWB control
            6'd37: reg_word = 16'hAC8D; // AWB control
            6'd38: reg_word = 16'h0E61; // COM5
            6'd39: reg_word = 16'h0F4B; // COM6
            6'd40: reg_word = 16'h1602; // RSVD
            6'd41: reg_word = 16'h1E07; // MVFP   : normal mirror/flip
            6'd42: reg_word = 16'h2102; // ADCCTR1
            6'd43: reg_word = 16'h2291; // ADCCTR2
            6'd44: reg_word = 16'h2907; // RSVD
            6'd45: reg_word = 16'h330B; // CHLF
            6'd46: reg_word = 16'h350B; // RSVD
            6'd47: reg_word = 16'h371D; // ADC
            6'd48: reg_word = 16'h3871; // ACOM
            6'd49: reg_word = 16'h392A; // OFON
            6'd50: reg_word = 16'h3C78; // COM12
            6'd51: reg_word = 16'h4D40; // RSVD
            default: reg_word = 16'hFFFF;
        endcase
    end

endmodule
