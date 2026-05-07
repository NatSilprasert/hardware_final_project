module ov7670_registers #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
) (
    input  wire [ADDR_WIDTH-1:0] index,
    output reg  [DATA_WIDTH-1:0] reg_word,
    output wire                  valid
);

    // RGB565/QVGA register table adapted from the working Vivado project in
    // project_1.srcs 2. The reference design performs two ID reads first; this
    // ROM keeps only the writes because this project's SCCB master is write-only.
    localparam REG_COUNT = 165;

    assign valid = (index < REG_COUNT);

    always @(*) begin
        reg_word = 16'hFFFF;

        case (index)
            8'd0:   reg_word = 16'h1214;
            8'd1:   reg_word = 16'h40D0;
            8'd2:   reg_word = 16'h3A04;
            8'd3:   reg_word = 16'h3DC8;
            8'd4:   reg_word = 16'h1E31;
            8'd5:   reg_word = 16'h6B00;
            8'd6:   reg_word = 16'h32B6;
            8'd7:   reg_word = 16'h1713;
            8'd8:   reg_word = 16'h1801;
            8'd9:   reg_word = 16'h1902;
            8'd10:  reg_word = 16'h1A7A;
            8'd11:  reg_word = 16'h030A;
            8'd12:  reg_word = 16'h0C00;
            8'd13:  reg_word = 16'h3E00;
            8'd14:  reg_word = 16'h7000;
            8'd15:  reg_word = 16'h7100;
            8'd16:  reg_word = 16'h7211;
            8'd17:  reg_word = 16'h7300;
            8'd18:  reg_word = 16'hA202;
            8'd19:  reg_word = 16'h1180;
            8'd20:  reg_word = 16'h7A20;
            8'd21:  reg_word = 16'h7B1C;
            8'd22:  reg_word = 16'h7C28;
            8'd23:  reg_word = 16'h7D3C;
            8'd24:  reg_word = 16'h7E55;
            8'd25:  reg_word = 16'h7F68;
            8'd26:  reg_word = 16'h8076;
            8'd27:  reg_word = 16'h8180;
            8'd28:  reg_word = 16'h8288;
            8'd29:  reg_word = 16'h838F;
            8'd30:  reg_word = 16'h8496;
            8'd31:  reg_word = 16'h85A3;
            8'd32:  reg_word = 16'h86AF;
            8'd33:  reg_word = 16'h87C4;
            8'd34:  reg_word = 16'h88D7;
            8'd35:  reg_word = 16'h89E8;
            8'd36:  reg_word = 16'h13E0;
            8'd37:  reg_word = 16'h0000;
            8'd38:  reg_word = 16'h1000;
            8'd39:  reg_word = 16'h0D00;
            8'd40:  reg_word = 16'h1428;
            8'd41:  reg_word = 16'hA505;
            8'd42:  reg_word = 16'hAB07;
            8'd43:  reg_word = 16'h2475;
            8'd44:  reg_word = 16'h2563;
            8'd45:  reg_word = 16'h26A5;
            8'd46:  reg_word = 16'h9F78;
            8'd47:  reg_word = 16'hA068;
            8'd48:  reg_word = 16'hA103;
            8'd49:  reg_word = 16'hA6DF;
            8'd50:  reg_word = 16'hA7DF;
            8'd51:  reg_word = 16'hA8F0;
            8'd52:  reg_word = 16'hA990;
            8'd53:  reg_word = 16'hAA94;
            8'd54:  reg_word = 16'h13EF;
            8'd55:  reg_word = 16'h0E61;
            8'd56:  reg_word = 16'h0F4B;
            8'd57:  reg_word = 16'h1602;
            8'd58:  reg_word = 16'h2102;
            8'd59:  reg_word = 16'h2291;
            8'd60:  reg_word = 16'h2907;
            8'd61:  reg_word = 16'h330B;
            8'd62:  reg_word = 16'h350B;
            8'd63:  reg_word = 16'h371D;
            8'd64:  reg_word = 16'h3871;
            8'd65:  reg_word = 16'h392A;
            8'd66:  reg_word = 16'h3C78;
            8'd67:  reg_word = 16'h4D40;
            8'd68:  reg_word = 16'h4E20;
            8'd69:  reg_word = 16'h6900;
            8'd70:  reg_word = 16'h7419;
            8'd71:  reg_word = 16'h8D4F;
            8'd72:  reg_word = 16'h8E00;
            8'd73:  reg_word = 16'h8F00;
            8'd74:  reg_word = 16'h9000;
            8'd75:  reg_word = 16'h9100;
            8'd76:  reg_word = 16'h9200;
            8'd77:  reg_word = 16'h9600;
            8'd78:  reg_word = 16'h9A80;
            8'd79:  reg_word = 16'hB084;
            8'd80:  reg_word = 16'hB10C;
            8'd81:  reg_word = 16'hB20E;
            8'd82:  reg_word = 16'hB382;
            8'd83:  reg_word = 16'hB80A;
            8'd84:  reg_word = 16'h4314;
            8'd85:  reg_word = 16'h44F0;
            8'd86:  reg_word = 16'h4534;
            8'd87:  reg_word = 16'h4658;
            8'd88:  reg_word = 16'h4728;
            8'd89:  reg_word = 16'h483A;
            8'd90:  reg_word = 16'h5988;
            8'd91:  reg_word = 16'h5A88;
            8'd92:  reg_word = 16'h5B44;
            8'd93:  reg_word = 16'h5C67;
            8'd94:  reg_word = 16'h5D49;
            8'd95:  reg_word = 16'h5E0E;
            8'd96:  reg_word = 16'h6404;
            8'd97:  reg_word = 16'h6520;
            8'd98:  reg_word = 16'h6605;
            8'd99:  reg_word = 16'h9404;
            8'd100: reg_word = 16'h9508;
            8'd101: reg_word = 16'h6C0A;
            8'd102: reg_word = 16'h6D55;
            8'd103: reg_word = 16'h6E11;
            8'd104: reg_word = 16'h6F9F;
            8'd105: reg_word = 16'h6A40;
            8'd106: reg_word = 16'h0140;
            8'd107: reg_word = 16'h0240;
            8'd108: reg_word = 16'h13E7;
            8'd109: reg_word = 16'h1500;
            8'd110: reg_word = 16'h4F80;
            8'd111: reg_word = 16'h5080;
            8'd112: reg_word = 16'h5100;
            8'd113: reg_word = 16'h5222;
            8'd114: reg_word = 16'h535E;
            8'd115: reg_word = 16'h5480;
            8'd116: reg_word = 16'h589E;
            8'd117: reg_word = 16'h4108;
            8'd118: reg_word = 16'h3F00;
            8'd119: reg_word = 16'h7505;
            8'd120: reg_word = 16'h76E1;
            8'd121: reg_word = 16'h4C00;
            8'd122: reg_word = 16'h7701;
            8'd123: reg_word = 16'h4B09;
            8'd124: reg_word = 16'hC9F0;
            8'd125: reg_word = 16'h4138;
            8'd126: reg_word = 16'h5640;
            8'd127: reg_word = 16'h3411;
            8'd128: reg_word = 16'h3B02;
            8'd129: reg_word = 16'hA489;
            8'd130: reg_word = 16'h9600;
            8'd131: reg_word = 16'h9730;
            8'd132: reg_word = 16'h9820;
            8'd133: reg_word = 16'h9930;
            8'd134: reg_word = 16'h9A84;
            8'd135: reg_word = 16'h9B29;
            8'd136: reg_word = 16'h9C03;
            8'd137: reg_word = 16'h9D4C;
            8'd138: reg_word = 16'h9E3F;
            8'd139: reg_word = 16'h7804;
            8'd140: reg_word = 16'h7901;
            8'd141: reg_word = 16'hC8F0;
            8'd142: reg_word = 16'h790F;
            8'd143: reg_word = 16'hC800;
            8'd144: reg_word = 16'h7910;
            8'd145: reg_word = 16'hC87E;
            8'd146: reg_word = 16'h790A;
            8'd147: reg_word = 16'hC880;
            8'd148: reg_word = 16'h790B;
            8'd149: reg_word = 16'hC801;
            8'd150: reg_word = 16'h790C;
            8'd151: reg_word = 16'hC80F;
            8'd152: reg_word = 16'h790D;
            8'd153: reg_word = 16'hC820;
            8'd154: reg_word = 16'h7909;
            8'd155: reg_word = 16'hC880;
            8'd156: reg_word = 16'h7902;
            8'd157: reg_word = 16'hC8C0;
            8'd158: reg_word = 16'h7903;
            8'd159: reg_word = 16'hC840;
            8'd160: reg_word = 16'h7905;
            8'd161: reg_word = 16'hC830;
            8'd162: reg_word = 16'h7926;
            8'd163: reg_word = 16'h0903;
            8'd164: reg_word = 16'h3B42;
            default: reg_word = 16'hFFFF;
        endcase
    end

endmodule
