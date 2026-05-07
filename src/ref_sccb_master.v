module ref_sccb_master (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] addr,
    input  wire [7:0] data,
    output reg        done,
    output reg        scl,
    inout  wire       sda
);

    localparam CLK_DIV = 10'd500;
    localparam TOTAL_BITS = 6'd27;

    localparam ST_IDLE  = 2'd0;
    localparam ST_RUN   = 2'd1;
    localparam ST_STOP  = 2'd2;
    localparam ST_DONE  = 2'd3;

    reg [1:0] state;
    reg [9:0] clk_count;
    reg [5:0] bit_count;
    reg       sda_out;
    reg       sda_oe;
    reg [7:0] addr_reg;
    reg [7:0] data_reg;

    assign sda = (sda_oe && !sda_out) ? 1'b0 : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            state     <= ST_IDLE;
            clk_count <= 10'd0;
            bit_count <= 6'd0;
            scl       <= 1'b1;
            sda_out   <= 1'b1;
            sda_oe    <= 1'b1;
            done      <= 1'b0;
            addr_reg  <= 8'd0;
            data_reg  <= 8'd0;
        end else begin
            done <= 1'b0;
            case (state)
                ST_IDLE: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    sda_oe  <= 1'b1;
                    if (start) begin
                        addr_reg  <= addr;
                        data_reg  <= data;
                        scl       <= 1'b1;
                        sda_out   <= 1'b0;  // start condition
                        sda_oe    <= 1'b1;
                        clk_count <= 10'd0;
                        bit_count <= 6'd0;
                        state     <= ST_RUN;
                    end
                end

                ST_RUN: begin
                    clk_count <= clk_count + 10'd1;
                    if (clk_count == CLK_DIV - 1) begin
                        clk_count <= 10'd0;
                        scl <= ~scl;
                        if (scl == 1'b1) begin
                            bit_count <= bit_count + 6'd1;
                            if (bit_count == TOTAL_BITS - 1) begin
                                state <= ST_STOP;
                            end
                        end
                    end
                end

                ST_STOP: begin
                    scl     <= 1'b1;
                    sda_oe  <= 1'b1;
                    sda_out <= 1'b1;
                    done    <= 1'b1;
                    state   <= ST_DONE;
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
