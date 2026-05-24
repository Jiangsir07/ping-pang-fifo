`timescale 1ns / 1ps

module tb_ping_pong_fifo;

    localparam WIDTH = 8;
    localparam DEPTH = 16;
    localparam CLK_PERIOD = 10;

    reg clk, rst_n;
    reg wr_en;
    reg [WIDTH-1:0] wr_data;
    wire wr_full;
    reg rd_en;
    wire [WIDTH-1:0] rd_data;
    wire rd_empty;
    wire swapping;
    wire buf_select;

    reg [WIDTH-1:0] expected_data;
    integer         total_writes, total_reads, swap_count;
    integer         mismatch_count;
    integer         idle_write_cycles, idle_read_cycles;

    ping_pong_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) u_dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data), .wr_full(wr_full),
        .rd_en(rd_en), .rd_data(rd_data), .rd_empty(rd_empty),
        .swapping(swapping), .buf_select(buf_select)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // Writer: ~80% duty cycle with random gapping
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en   <= 1'b0;
            wr_data <= 8'd0;
        end else begin
            if (!$urandom_range(0, 4) && !wr_full)
                wr_en <= 1'b1;
            else
                wr_en <= 1'b0;

            if (wr_en && !wr_full)
                wr_data <= wr_data + 1;
        end
    end

    // Reader: ~70% duty cycle
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_en <= 1'b0;
        end else begin
            if (!$urandom_range(0, 2) && !rd_empty)
                rd_en <= 1'b1;
            else
                rd_en <= 1'b0;
        end
    end

    // Scoreboard
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_data  <= 8'd0;
            total_writes   <= 0;
            total_reads    <= 0;
            swap_count     <= 0;
            mismatch_count <= 0;
        end else begin
            if (wr_en && !wr_full) begin
                total_writes <= total_writes + 1;
            end
            if (rd_en && !rd_empty) begin
                if (rd_data !== expected_data) begin
                    mismatch_count <= mismatch_count + 1;
                    $display("[%0t] ** MISMATCH **  expected=%0d  got=%0d  (read #%0d)",
                             $time, expected_data, rd_data, total_reads);
                end
                expected_data <= expected_data + 1;
                total_reads  <= total_reads + 1;
            end
            if (swapping) begin
                swap_count <= swap_count + 1;
                $display("[%0t] ** SWAP #%0d **  → %s",
                         $time, swap_count + 1, buf_select ? "wrB/rdA" : "wrA/rdB");
            end
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            // reset counters handled with rst_n in the main always block
        end else begin
            if (wr_full)  idle_write_cycles <= idle_write_cycles + 1;
            if (rd_empty) idle_read_cycles  <= idle_read_cycles + 1;
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        idle_write_cycles = 0;
        idle_read_cycles  = 0;

        $display("\n===========================================");
        $display(" Ping-Pong FIFO Testbench  (XPM FIFO model)");
        $display(" WIDTH=%0d  DEPTH=%0d  CLK=%0dns", WIDTH, DEPTH, CLK_PERIOD);
        $display("===========================================\n");

        repeat(5) @(posedge clk);
        rst_n = 1;
        $display("[%0t] Reset released", $time);

        repeat(2000) @(posedge clk);

        // Drain remaining data
        $display("\n[%0t] Draining remaining FIFO data...", $time);
        repeat(500) @(posedge clk);

        $display("\n===========================================");
        $display(" Simulation Summary");
        $display("===========================================");
        $display(" Total writes       : %0d", total_writes);
        $display(" Total reads        : %0d", total_reads);
        $display(" Swap count         : %0d", swap_count);
        $display(" Mismatches         : %0d", mismatch_count);
        $display(" Writer idle cycles : %0d (FIFO full)", idle_write_cycles);
        $display(" Reader idle cycles : %0d (FIFO empty)", idle_read_cycles);

        if (mismatch_count == 0 && total_reads > 0)
            $display("\n >>> RESULT: PASS  <<<\n");
        else if (total_reads == 0)
            $display("\n >>> RESULT: FAIL — no data read <<<\n");
        else
            $display("\n >>> RESULT: FAIL — %0d mismatches <<<\n", mismatch_count);

        $finish;
    end

    initial begin
        $dumpfile("tb_ping_pong_fifo.vcd");
        $dumpvars(0, tb_ping_pong_fifo);
    end

endmodule
