// XPM FIFO Wrapper
//   SYNTHESIS defined (Vivado) : instantiates xpm_fifo_sync → BRAM/distributed RAM hard core
//   SYNTHESIS not defined (sim) : behavioral model matching XPM interface

module xpm_fifo_wrapper #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             wr_clk,
    input  wire             rst,          // XPM convention: active-high reset
    input  wire             wr_en,
    input  wire [WIDTH-1:0] din,
    output wire             full,
    output wire             almost_full,
    input  wire             rd_en,
    output wire [WIDTH-1:0] dout,
    output wire             empty,
    output wire             almost_empty,
    output wire [31:0]      data_count
);

`ifdef SYNTHESIS
    // Vivado synthesis: use Xilinx Parameterized Macro (maps to hard FIFO primitives)
    xpm_fifo_sync #(
        .FIFO_WRITE_DEPTH       (DEPTH),
        .WRITE_DATA_WIDTH       (WIDTH),
        .READ_DATA_WIDTH        (WIDTH),
        .READ_MODE              ("fwft"),          // First-Word Fall-Through
        .FIFO_MEMORY_TYPE       ("auto"),          // Let Vivado choose BRAM / distributed
        .USE_ADV_FEATURES       ("0707"),          // almost_full + almost_empty + data_count
        .FULL_RESET_VALUE       (0),
        .CDC_SYNC_STAGES        (2),
        .RELATED_CLOCKS         (1),
        .SIM_ASSERT_CHK         (0),
        .WRITE_DATA_COUNT_WIDTH ($clog2(DEPTH) + 1),
        .READ_DATA_COUNT_WIDTH  ($clog2(DEPTH) + 1)
    ) u_xpm_fifo (
        .wr_clk        (wr_clk),
        .rst           (rst),
        .wr_en         (wr_en),
        .din           (din),
        .full          (full),
        .almost_full   (almost_full),
        .rd_en         (rd_en),
        .dout          (dout),
        .empty         (empty),
        .almost_empty  (almost_empty),
        .data_count    (data_count),
        .wr_data_count (),
        .rd_data_count (),
        .overflow      (),
        .underflow     (),
        .wr_ack        (),
        .wr_rst_busy   (),
        .rd_rst_busy   (),
        .sleep         (1'b0),
        .injectsbiterr (1'b0),
        .injectdbiterr (1'b0),
        .sbiterr       (),
        .dbiterr       ()
    );

`else
    // Behavioral model for simulation (QuestaSim / ModelSim)
    // Same XPM-compliant interface, functionally identical
    localparam ADDR_W = $clog2(DEPTH);

    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0]  wr_ptr, rd_ptr;
    reg [3:0]        rst_shft;

    wire [ADDR_W:0] count;
    assign count = wr_ptr - rd_ptr;

    assign data_count   = { {(32-ADDR_W-1){1'b0}}, count };
    assign empty        = (wr_ptr == rd_ptr);
    assign full         = (wr_ptr[ADDR_W] != rd_ptr[ADDR_W]) && (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);
    assign almost_full  = (count >= DEPTH - 2);
    assign almost_empty = (count <= 2);
    assign dout         = mem[rd_ptr[ADDR_W-1:0]];

    // Extend reset for at least 4 cycles (XPM requirement)
    always @(posedge wr_clk) begin
        if (rst) begin
            rst_shft <= 4'hF;
        end else begin
            rst_shft <= {1'b0, rst_shft[3:1]};
        end
    end

    wire rst_active = |rst_shft;

    always @(posedge wr_clk) begin
        if (rst_active) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_W-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge wr_clk) begin
        if (rst_active) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

`endif

endmodule
