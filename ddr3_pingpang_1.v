	module ddr3_pingpang_1 (
		input						clk						,
		input						rst_n					,
		
		input 		[32-1:0]		addr_size				,
		
		input		[32-1:0]		din						,
		output	reg					din_rd_en				,
		input						din_empty				,
		input						din_alempty				,
		
		output		[32-1:0]		dout					,
		input						dout_rd_en				,
		output						dout_empty				,
		output						dout_alempty			,
	
		output 		[13:0]			ddr3_0_addr   			,
		output 		[2:0]			ddr3_0_ba		 		,
		output						ddr3_0_cas_n	 		,
		output 		[0:0]			ddr3_0_ck_n	 			,
		output 		[0:0]			ddr3_0_ck_p	 			,
		output 		[0:0]			ddr3_0_cke	 			,
		output						ddr3_0_ras_n	 		,
		output						ddr3_0_reset_n 			,
		output						ddr3_0_we_n	 			,
		inout 		[7:0]			ddr3_0_dq		 		,
		inout 		[0:0]			ddr3_0_dqs_n	 		,
		inout 		[0:0]			ddr3_0_dqs_p	 		,
		output 		[0:0]			init_0_done	 			,
		output 		[0:0]			ddr3_0_cs_n	 			,
		output 		[0:0]			ddr3_0_dm		 		,
	    output                  	ddr3_0_odt				,
	    input	                  	ddr3_0_sys_clk			,
		
		output 		[13:0]			ddr3_1_addr   			,
		output 		[2:0]			ddr3_1_ba		 		,
		output						ddr3_1_cas_n	 		,
		output 		[0:0]			ddr3_1_ck_n	 			,
		output 		[0:0]			ddr3_1_ck_p	 			,
		output 		[0:0]			ddr3_1_cke	 			,
		output						ddr3_1_ras_n	 		,
		output						ddr3_1_reset_n 			,
		output						ddr3_1_we_n	 			,
		inout 		[7:0]			ddr3_1_dq		 		,
		inout 		[0:0]			ddr3_1_dqs_n	 		,
		inout 		[0:0]			ddr3_1_dqs_p	 		,
		output 		[0:0]			init_1_done	 			,
		output 		[0:0]			ddr3_1_cs_n	 			,
		output 		[0:0]			ddr3_1_dm		 		,
	    output                  	ddr3_1_odt				,
		input	                  	ddr3_1_sys_clk			
	);
	
	reg 	wr_flag_0 = 0;
	wire  	wr_flag_1 = ~wr_flag_0;
	
	// wire[32-1:0]addr_size = 32'h0008_0000;
	
	reg[32-1:0]wr_cnt,rd_cnt;
	
	wire[32-1:0]	ddr3_0_din			    ;
	wire			ddr3_0_din_wr_en		;
	wire 			ddr3_0_din_prog_full	;
	
	wire[32-1:0]	ddr3_1_din			    ;
	wire			ddr3_1_din_wr_en		;
	wire 			ddr3_1_din_prog_full	;
	
	reg [32-1:0]	fifo_din			;
	reg				fifo_wr_en 		  	;
	wire			fifo_rd_en 		  	;
	wire [32-1:0]	fifo_dout		  	;
	wire			fifo_full		  	;
	wire			fifo_almost_full  	;
	wire			fifo_prog_full 	  	;
	wire			fifo_empty 		  	;
	wire			fifo_almost_empty  	;
	
	wire[32-1:0]	ddr3_0_dout			;
	wire			ddr3_0_dout_rd_en	;
	wire			ddr3_0_dout_empty	;
	wire			ddr3_0_dout_alempty	;
	
	wire[32-1:0]	ddr3_1_dout			;
	wire			ddr3_1_dout_rd_en	;
	wire			ddr3_1_dout_empty	;
	wire			ddr3_1_dout_alempty	;	
	
	always@( posedge clk )begin
		if( ddr3_0_din_prog_full == 1'b1 || ddr3_1_din_prog_full == 1'b1)begin
			din_rd_en <= 1'b0;
		end
		else if( din_alempty == 1'b0 )begin
			din_rd_en <= 1'b1;
		end
		else if( din_rd_en == 1'b1 )begin
			din_rd_en <= 1'b0;
		end
		else begin
			din_rd_en <= ~din_empty;
		end
	end
	
	wire ddr3_0_wr_full;
	wire ddr3_1_wr_full;

	always@( posedge clk )begin
		if( rst_n == 1'b0 )begin
			wr_cnt <= 32'd0;
		end
		else if( wr_cnt >= addr_size - 1 && din_rd_en == 1'b1 )begin
			wr_cnt <= 32'd0;
		end
		else if( din_rd_en == 1'b1 )begin
			wr_cnt <= wr_cnt + 1'b1;
		end
		else ;
	end
	
	always@( posedge clk )begin
		if( rst_n == 1'b0 )begin
			wr_flag_0 <= 1'b1;
		end
		else if( wr_cnt >= addr_size - 1 && din_rd_en == 1'b1 )begin
			wr_flag_0 <= ~wr_flag_0;
		end
		else ;
	end
	
	//Х┴┐пок	
	reg rd_flag_0;
	reg dd3_dout_rd_en;
	wire [31:0] dd3_dout = rd_flag_0 ? ddr3_0_dout : ddr3_1_dout;
	
	wire dd3_dout_alempty = rd_flag_0 ? ddr3_0_dout_alempty : ddr3_1_dout_alempty;
	wire dd3_dout_empty   = rd_flag_0 ? ddr3_0_dout_empty : ddr3_1_dout_empty;
	assign ddr3_0_dout_rd_en = rd_flag_0 ? dd3_dout_rd_en : 0;
	assign ddr3_1_dout_rd_en = rd_flag_0 == 1'b0 ? dd3_dout_rd_en : 0;
	
	
	always@( posedge clk )begin
		if( rst_n == 1'b0 )begin
			rd_flag_0 <= 1'b1;
		end
		else if( rd_cnt >= addr_size - 1 && dd3_dout_rd_en == 1'b1 )begin
			rd_flag_0 <= ~rd_flag_0;
		end
		else ;
	end

	always@( posedge clk )begin
		if( rst_n == 1'b0 )begin
			rd_cnt <= 32'd0;
		end
		else if( rd_cnt >= addr_size - 1 && dd3_dout_rd_en == 1'b1 )begin
			rd_cnt <= 32'd0;
		end
		else if( dd3_dout_rd_en == 1'b1 )begin
			rd_cnt <= rd_cnt + 1'b1;
		end
		else ;
	end

	always@( posedge clk )begin
		if( fifo_prog_full == 1'b1)begin
			dd3_dout_rd_en <= 1'b0;
		end
		else if( dd3_dout_alempty == 1'b0 )begin
			dd3_dout_rd_en <= 1'b1;
		end
		else if( dd3_dout_rd_en == 1'b1 )begin
			dd3_dout_rd_en <= 1'b0;
		end
		else begin
			dd3_dout_rd_en <= ~dd3_dout_empty;
		end
	end	
	
	assign dout = fifo_dout;
	assign fifo_rd_en = dout_rd_en;
	assign dout_empty = fifo_empty;
	assign dout_alempty = fifo_almost_empty;
	
	assign ddr3_0_din = din;
	assign ddr3_1_din = din;
	
	assign ddr3_0_din_wr_en = din_rd_en & wr_flag_0;
	assign ddr3_1_din_wr_en = din_rd_en & wr_flag_1;
	
	wire wr_flag_0_clk_ddr3;
	wire wr_flag_1_clk_ddr3;
	
	wire clk_ddr3_0;
	wire clk_ddr3_1;

	fifo_async_16x32 fifo(
		.wr_clk 		( clk 					),
		.rd_clk 		( clk	 				),
		.rst 			(~rst_n					),
		.din 			( dd3_dout				),
		.wr_en 			( dd3_dout_rd_en 		),
		.rd_en 			( fifo_rd_en 			),
		.dout			( fifo_dout				),
		.full			( fifo_full				),
		.almost_full 	( fifo_almost_full 		),
		.prog_full 		( fifo_prog_full 		),
		.empty 			( fifo_empty 			),
		.almost_empty 	( fifo_almost_empty 	)
	);
	
	
	fifo_ddr_0#(
		.ADDR_WIDTH  	( 32						),
		.ADDR_INITIAL	( 32'h0000_0000	     		)
	)ddr3_0(		
		.clk			( clk						),
		.rst_n			( rst_n						),
		.wr_flag		( wr_flag_0_clk_ddr3		),
		.addr_size		( addr_size					),
		.ddr3_wr_full	( ddr3_0_wr_full			),
		.clk_ddr3		( clk_ddr3_0				),
	
		.din			( ddr3_0_din				),
		.din_wr_en		( ddr3_0_din_wr_en			),
		.din_prog_full	( ddr3_0_din_prog_full		),
		
		.dout			( ddr3_0_dout				),
		.dout_rd_en		( ddr3_0_dout_rd_en			),
		.dout_empty		( ddr3_0_dout_empty			),
		.dout_alempty	( ddr3_0_dout_alempty		),
	
		.ddr3_addr   	( ddr3_0_addr   			),
		.ddr3_ba		( ddr3_0_ba		 			),
		.ddr3_cas_n	 	( ddr3_0_cas_n	 			),
		.ddr3_ck_n	 	( ddr3_0_ck_n	 			),
		.ddr3_ck_p	 	( ddr3_0_ck_p	 			),
		.ddr3_cke	 	( ddr3_0_cke	 			),
		.ddr3_ras_n	 	( ddr3_0_ras_n	 			),
		.ddr3_reset_n 	( ddr3_0_reset_n 			),
		.ddr3_we_n	 	( ddr3_0_we_n	 			),
		.ddr3_dq		( ddr3_0_dq		 			),
		.ddr3_dqs_n	 	( ddr3_0_dqs_n	 			),
		.ddr3_dqs_p	 	( ddr3_0_dqs_p	 			),
		.init_done	 	( init_0_done	 			),
		.ddr3_cs_n	 	( ddr3_0_cs_n	 			),
		.ddr3_dm		( ddr3_0_dm		 			),
		.ddr3_odt	    ( ddr3_0_odt				),
		.ddr3_sys_clk	( ddr3_0_sys_clk			)
	);
	
	fifo_ddr_1#(
		.ADDR_WIDTH  	( 32						),
		.ADDR_INITIAL	( 32'hFFFF_FFFF     		)
	)ddr3_1(	
		.clk			( clk						),
		.rst_n			( rst_n						),
		.wr_flag		( wr_flag_1_clk_ddr3		),
		.addr_size		( addr_size				 	),
		.ddr3_wr_full	( ddr3_1_wr_full			),
		.clk_ddr3		( clk_ddr3_1				),
		
		.din			( ddr3_1_din				),
		.din_wr_en		( ddr3_1_din_wr_en			),
		.din_prog_full	( ddr3_1_din_prog_full		),
	
		.dout			( ddr3_1_dout				),
		.dout_rd_en		( ddr3_1_dout_rd_en			),
		.dout_empty		( ddr3_1_dout_empty			),
		.dout_alempty	( ddr3_1_dout_alempty		),
	
		.ddr3_addr   	( ddr3_1_addr   			),
		.ddr3_ba		( ddr3_1_ba		 			),
		.ddr3_cas_n	 	( ddr3_1_cas_n	 			),
		.ddr3_ck_n	 	( ddr3_1_ck_n	 			),
		.ddr3_ck_p	 	( ddr3_1_ck_p	 			),
		.ddr3_cke	 	( ddr3_1_cke	 			),
		.ddr3_ras_n	 	( ddr3_1_ras_n	 			),
		.ddr3_reset_n 	( ddr3_1_reset_n 			),
		.ddr3_we_n	 	( ddr3_1_we_n	 			),
		.ddr3_dq		( ddr3_1_dq		 			),
		.ddr3_dqs_n	 	( ddr3_1_dqs_n	 			),
		.ddr3_dqs_p	 	( ddr3_1_dqs_p	 			),
		.init_done	 	( init_1_done	 			),
		.ddr3_cs_n	 	( ddr3_1_cs_n	 			),
		.ddr3_dm		( ddr3_1_dm		 			),
		.ddr3_odt	    ( ddr3_1_odt				),
		.ddr3_sys_clk	( ddr3_1_sys_clk			)
	);
	
	
	ila_ddr3_pingpang ila_0(
		.clk 		( clk					),
		.probe0		( din					),
		.probe1		( din_alempty			),
		.probe2		( din_empty				),
		.probe3		( din_rd_en				),
		.probe4		( dout					),
		.probe5		( dout_rd_en			),
		.probe6		( dout_empty			),
		.probe7		( dout_alempty			),
		.probe8		( ddr3_0_din_prog_full	),
		.probe9		( ddr3_1_din_prog_full	),
		.probe10	( wr_flag_0				),
		.probe11	( wr_flag_1				),
		.probe12	( ddr3_0_wr_full		),
		.probe13	( ddr3_1_wr_full		),
		.probe14	( wr_cnt				)
	);
	
	
	endmodule
