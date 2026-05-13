module frame_buffer #(
    parameter FRAME_WIDTH  = 320,
    parameter FRAME_HEIGHT = 240,
    parameter ADDR_WIDTH   = 17,
    parameter DATA_WIDTH   = 12,
    parameter DEPTH        = 76800
) (
    input  wire                   wr_clk,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    input  wire                   rd_clk,
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output reg  [DATA_WIDTH-1:0]  rd_data
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge wr_clk) begin
        if (wr_en && (wr_addr < DEPTH)) begin
            mem[wr_addr] <= wr_data;
        end
    end

    always @(posedge rd_clk) begin
        if (rd_addr < DEPTH)
            rd_data <= mem[rd_addr];
        else
            rd_data <= {DATA_WIDTH{1'b0}};
    end

endmodule
