// Ping-pong (double buffer) using two XPM synchronous FIFOs
// Write to one FIFO while reading from the other; swap when write buffer fills and read buffer drains
module ping_pong_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,        // active-low reset (inverted internally for XPM)

    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,
    output wire             wr_full,

    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,
    output wire             rd_empty,

    output wire             swapping,
    output wire             buf_select     // 0: wrA/rdB, 1: wrB/rdA
);
    wire rst = ~rst_n;                      // XPM uses active-high reset

    wire [WIDTH-1:0] fifo_a_din, fifo_b_din;
    wire [WIDTH-1:0] fifo_a_dout, fifo_b_dout;
    wire             fifo_a_wr, fifo_b_wr, fifo_a_rd, fifo_b_rd;
    wire             fifo_a_full, fifo_b_full;
    wire             fifo_a_empty, fifo_b_empty;
    wire [31:0]      fifo_a_dcnt, fifo_b_dcnt;

    reg  select;
    reg  swap_pulse;

    assign buf_select = select;

    // Write / read routing
    assign fifo_a_din  = wr_data;
    assign fifo_b_din  = wr_data;
    assign fifo_a_wr   = (!select) && wr_en;
    assign fifo_b_wr   =  select   && wr_en;
    assign fifo_a_rd   =  select   && rd_en;
    assign fifo_b_rd   = (!select) && rd_en;
    assign rd_data     = select ? fifo_a_dout : fifo_b_dout;
    assign wr_full     = select ? fifo_b_full : fifo_a_full;
    assign rd_empty    = select ? fifo_a_empty : fifo_b_empty;

    // ---- Swap controller ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            select     <= 1'b0;
            swap_pulse <= 1'b0;
        end else begin
            swap_pulse <= 1'b0;
            if (!select) begin
                if (fifo_a_full && fifo_b_empty) begin
                    select     <= 1'b1;
                    swap_pulse <= 1'b1;
                end
            end else begin
                if (fifo_b_full && fifo_a_empty) begin
                    select     <= 1'b0;
                    swap_pulse <= 1'b1;
                end
            end
        end
    end

    assign swapping = swap_pulse;

    // ---- XPM FIFO A ----
    xpm_fifo_wrapper #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_fifo_a (
        .wr_clk       (clk),
        .rst          (rst),
        .wr_en        (fifo_a_wr),
        .din          (fifo_a_din),
        .full         (fifo_a_full),
        .almost_full  (),
        .rd_en        (fifo_a_rd),
        .dout         (fifo_a_dout),
        .empty        (fifo_a_empty),
        .almost_empty (),
        .data_count   (fifo_a_dcnt)
    );

    // ---- XPM FIFO B ----
    xpm_fifo_wrapper #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_fifo_b (
        .wr_clk       (clk),
        .rst          (rst),
        .wr_en        (fifo_b_wr),
        .din          (fifo_b_din),
        .full         (fifo_b_full),
        .almost_full  (),
        .rd_en        (fifo_b_rd),
        .dout         (fifo_b_dout),
        .empty        (fifo_b_empty),
        .almost_empty (),
        .data_count   (fifo_b_dcnt)
    );

endmodule
