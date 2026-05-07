module ref_ov7670_init (
    input  wire       clk,
    input  wire       rst,
    output reg        sccb_start,
    output reg  [7:0] sccb_addr,
    output reg  [7:0] sccb_data,
    input  wire       sccb_done,
    output reg        cam_rst_out,
    output reg        init_done
);

    localparam DELAY_1MS   = 24'd100_000;
    localparam DELAY_300MS  = 28'd30_000_000;

    localparam [3:0] ST_RESET_ASSERT  = 4'd0;
    localparam [3:0] ST_RESET_WAIT    = 4'd1;
    localparam [3:0] ST_RESET_RELEASE = 4'd2;
    localparam [3:0] ST_POST_RESET    = 4'd3;
    localparam [3:0] ST_SWRESET_SEND  = 4'd4;
    localparam [3:0] ST_SWRESET_WAIT  = 4'd5;
    localparam [3:0] ST_SETTLE_WAIT   = 4'd6;
    localparam [3:0] ST_SEND_REG      = 4'd7;
    localparam [3:0] ST_WAIT_SCCB     = 4'd8;
    localparam [3:0] ST_NEXT_REG      = 4'd9;
    localparam [3:0] ST_INIT_DONE     = 4'd10;

    reg [3:0]  state;
    reg [27:0] delay_count;
    reg [6:0]  reg_index;
    wire [15:0] current_entry_wire = get_reg_entry(reg_index);

    localparam NUM_REGS = 7'd72;

    function [15:0] get_reg_entry;
        input [6:0] index;
        begin
            case (index)
                7'd0:  get_reg_entry = {8'h12, 8'h14};
                7'd1:  get_reg_entry = {8'h40, 8'hD0};
                7'd2:  get_reg_entry = {8'h3A, 8'h04};
                7'd3:  get_reg_entry = {8'h3D, 8'hC8};
                7'd4:  get_reg_entry = {8'h11, 8'h80};
                7'd5:  get_reg_entry = {8'h6B, 8'h00};
                7'd6:  get_reg_entry = {8'h1E, 8'h31};
                7'd7:  get_reg_entry = {8'h17, 8'h13};
                7'd8:  get_reg_entry = {8'h18, 8'h01};
                7'd9:  get_reg_entry = {8'h32, 8'hB6};
                7'd10: get_reg_entry = {8'h19, 8'h02};
                7'd11: get_reg_entry = {8'h1A, 8'h7A};
                7'd12: get_reg_entry = {8'h03, 8'h0A};
                7'd13: get_reg_entry = {8'h0C, 8'h00};
                7'd14: get_reg_entry = {8'h3E, 8'h00};
                7'd15: get_reg_entry = {8'h70, 8'h00};
                7'd16: get_reg_entry = {8'h71, 8'h00};
                7'd17: get_reg_entry = {8'h72, 8'h11};
                7'd18: get_reg_entry = {8'h73, 8'h00};
                7'd19: get_reg_entry = {8'hA2, 8'h02};
                7'd20: get_reg_entry = {8'h15, 8'h00};
                7'd21: get_reg_entry = {8'h7A, 8'h20};
                7'd22: get_reg_entry = {8'h7B, 8'h1C};
                7'd23: get_reg_entry = {8'h7C, 8'h28};
                7'd24: get_reg_entry = {8'h7D, 8'h3C};
                7'd25: get_reg_entry = {8'h7E, 8'h55};
                7'd26: get_reg_entry = {8'h7F, 8'h68};
                7'd27: get_reg_entry = {8'h80, 8'h76};
                7'd28: get_reg_entry = {8'h81, 8'h80};
                7'd29: get_reg_entry = {8'h82, 8'h88};
                7'd30: get_reg_entry = {8'h83, 8'h8F};
                7'd31: get_reg_entry = {8'h84, 8'h96};
                7'd32: get_reg_entry = {8'h85, 8'hA3};
                7'd33: get_reg_entry = {8'h86, 8'hAF};
                7'd34: get_reg_entry = {8'h87, 8'hC4};
                7'd35: get_reg_entry = {8'h88, 8'hD7};
                7'd36: get_reg_entry = {8'h89, 8'hE8};
                7'd37: get_reg_entry = {8'h13, 8'hE0};
                7'd38: get_reg_entry = {8'h00, 8'h00};
                7'd39: get_reg_entry = {8'h10, 8'h00};
                7'd40: get_reg_entry = {8'h0D, 8'h00};
                7'd41: get_reg_entry = {8'h14, 8'h28};
                7'd42: get_reg_entry = {8'hA5, 8'h05};
                7'd43: get_reg_entry = {8'hAB, 8'h07};
                7'd44: get_reg_entry = {8'h24, 8'h75};
                7'd45: get_reg_entry = {8'h25, 8'h63};
                7'd46: get_reg_entry = {8'h26, 8'hA5};
                7'd47: get_reg_entry = {8'h9F, 8'h78};
                7'd48: get_reg_entry = {8'hA0, 8'h68};
                7'd49: get_reg_entry = {8'hA1, 8'h03};
                7'd50: get_reg_entry = {8'hA6, 8'hDF};
                7'd51: get_reg_entry = {8'hA7, 8'hDF};
                7'd52: get_reg_entry = {8'hA8, 8'hF0};
                7'd53: get_reg_entry = {8'hA9, 8'h90};
                7'd54: get_reg_entry = {8'hAA, 8'h94};
                7'd55: get_reg_entry = {8'h13, 8'hEF};
                7'd56: get_reg_entry = {8'h0E, 8'h61};
                7'd57: get_reg_entry = {8'h0F, 8'h4B};
                7'd58: get_reg_entry = {8'h16, 8'h02};
                7'd59: get_reg_entry = {8'h4F, 8'h80};
                7'd60: get_reg_entry = {8'h50, 8'h80};
                7'd61: get_reg_entry = {8'h51, 8'h00};
                7'd62: get_reg_entry = {8'h52, 8'h22};
                7'd63: get_reg_entry = {8'h53, 8'h5E};
                7'd64: get_reg_entry = {8'h54, 8'h80};
                7'd65: get_reg_entry = {8'h58, 8'h9E};
                7'd66: get_reg_entry = {8'h6C, 8'h0A};
                7'd67: get_reg_entry = {8'h6D, 8'h55};
                7'd68: get_reg_entry = {8'h6E, 8'h11};
                7'd69: get_reg_entry = {8'h6F, 8'h9F};
                7'd70: get_reg_entry = {8'h01, 8'h40};
                7'd71: get_reg_entry = {8'h02, 8'h40};
                default: get_reg_entry = {8'hFF, 8'hFF};
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state       <= ST_RESET_ASSERT;
            delay_count  <= 28'd0;
            reg_index    <= 7'd0;
            sccb_start   <= 1'b0;
            sccb_addr    <= 8'd0;
            sccb_data    <= 8'd0;
            cam_rst_out  <= 1'b0;
            init_done    <= 1'b0;
        end else begin
            sccb_start <= 1'b0;
            case (state)
                ST_RESET_ASSERT: begin
                    cam_rst_out <= 1'b0;
                    delay_count <= 28'd0;
                    state <= ST_RESET_WAIT;
                end
                ST_RESET_WAIT: begin
                    delay_count <= delay_count + 28'd1;
                    if (delay_count >= DELAY_1MS) begin
                        state <= ST_RESET_RELEASE;
                        delay_count <= 28'd0;
                    end
                end
                ST_RESET_RELEASE: begin
                    cam_rst_out <= 1'b1;
                    delay_count <= 28'd0;
                    state <= ST_POST_RESET;
                end
                ST_POST_RESET: begin
                    delay_count <= delay_count + 28'd1;
                    if (delay_count >= DELAY_1MS) begin
                        state <= ST_SWRESET_SEND;
                        delay_count <= 28'd0;
                    end
                end
                ST_SWRESET_SEND: begin
                    if (!sccb_done) begin
                        sccb_start <= 1'b1;
                        sccb_addr  <= 8'h12;
                        sccb_data  <= 8'h80;
                        state      <= ST_SWRESET_WAIT;
                    end
                end
                ST_SWRESET_WAIT: begin
                    if (sccb_done) begin
                        state <= ST_SETTLE_WAIT;
                        delay_count <= 28'd0;
                    end
                end
                ST_SETTLE_WAIT: begin
                    delay_count <= delay_count + 28'd1;
                    if (delay_count >= DELAY_300MS) begin
                        state <= ST_SEND_REG;
                        reg_index <= 7'd0;
                    end
                end
                ST_SEND_REG: begin
                    if (current_entry_wire != 16'hFFFF) begin
                        if (!sccb_done) begin
                            sccb_start <= 1'b1;
                            sccb_addr  <= current_entry_wire[15:8];
                            sccb_data  <= current_entry_wire[7:0];
                            state      <= ST_WAIT_SCCB;
                        end
                    end else begin
                        state <= ST_INIT_DONE;
                    end
                end
                ST_WAIT_SCCB: begin
                    if (sccb_done) begin
                        state <= ST_NEXT_REG;
                    end
                end
                ST_NEXT_REG: begin
                    reg_index <= reg_index + 7'd1;
                    state <= ST_SEND_REG;
                end
                ST_INIT_DONE: begin
                    init_done <= 1'b1;
                end
            endcase
        end
    end

endmodule
