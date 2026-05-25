	module fifo_ddr_0#(
		parameter ADDR_WIDTH  	= 32	,
		parameter ADDR_INITIAL	= 32'h0000_0000
	)(
		input						clk						,
		input						rst_n					,
		input						wr_flag					,
		input		[ADDR_WIDTH-1:0]addr_size				,
		output						ddr3_wr_full			,
		output						clk_ddr3				,
	
		input		[32-1:0]		din						,
		input						din_wr_en				,
		output						din_prog_full			,
		
		output		[32-1:0]		dout					,
		input						dout_rd_en				,
		output						dout_empty				,
		output						dout_alempty			,
		
		output 		[13:0]			ddr3_addr   			,
		output 		[2:0]			ddr3_ba		 			,
		output						ddr3_cas_n	 			,
		output 		[0:0]			ddr3_ck_n	 			,
		output 		[0:0]			ddr3_ck_p	 			,
		output 		[0:0]			ddr3_cke	 			,
		output						ddr3_ras_n	 			,
		output						ddr3_reset_n 			,
		output						ddr3_we_n	 			,
		inout 		[7:0]			ddr3_dq		 			,
		inout 		[0:0]			ddr3_dqs_n	 			,
		inout 		[0:0]			ddr3_dqs_p	 			,
		output 		[0:0]			init_done	 			,
		output 		[0:0]			ddr3_cs_n	 			,
		output 		[0:0]			ddr3_dm		 			,
	    output                  	ddr3_odt				,
	    input	                  	ddr3_sys_clk				
	);
	
//	wire					clk_ddr3			;
	wire					rst_n_ddr			;
	
	reg  [ADDR_WIDTH-1:0]	addr            	;
	wire [28-1:0]			app_addr            ;
	wire [2:0]				app_cmd             ;
	wire 					app_en              ;
	wire [64-1:0]			app_wdf_data        ;
	wire 					app_wdf_end         ;
	wire 					app_wdf_wren        ;
	wire [64-1:0]			app_rd_data         ;
	wire 					app_rd_data_end     ;
	wire 					app_rd_data_valid   ;
	wire 					app_rdy             ;
	wire 					app_wdf_rdy         ;
	
	wire [32-1:0]	fifo_wr_din			  ;	wire [32-1:0]	fifo_rd_din			  ;
	wire			fifo_wr_wr_en 		  ; wire			fifo_rd_wr_en 		  ;
	wire			fifo_wr_rd_en 		  ; wire			fifo_rd_rd_en 		  ;
	wire [32-1:0]	fifo_wr_dout		  ; wire [32-1:0]	fifo_rd_dout		  ;
	wire			fifo_wr_full		  ; wire			fifo_rd_full		  ;
	wire			fifo_wr_almost_full   ; wire			fifo_rd_almost_full   ;
	wire			fifo_wr_prog_full 	  ; wire			fifo_rd_prog_full 	  ;
	wire			fifo_wr_empty 		  ; wire			fifo_rd_empty 		  ;
	wire			fifo_wr_almost_empty  ; wire			fifo_rd_almost_empty  ;
	
	
	reg rd_flag;
	wire app_en_rd = rd_flag && fifo_rd_prog_full == 1'b0;
	wire  app_en_wr ;
	wire app_rdwr_en = (app_en_wr == 1'b1  || (app_rdy == 1'b1 && app_en_rd == 1'b1 )) ? 1'b1 : 1'b0;

	
	always@( posedge clk_ddr3 )begin
		if( rst_n_ddr == 1'b0 )begin
			rd_flag <= 1'b0;
		end
		else if( app_rdwr_en == 1'b1 && addr ==  addr_size - 1 )begin
			rd_flag <= ~rd_flag;
		end
		else ;
	end
	
	assign din_prog_full = fifo_wr_prog_full;

	assign fifo_wr_din 		= din		;
	assign fifo_wr_wr_en 	= din_wr_en	;
	
	
	always@( posedge clk_ddr3 )begin	
		if( rst_n_ddr == 1'b0 )begin
			addr <= {ADDR_WIDTH{1'b0}};
		end
		else if( app_rdwr_en == 1'b1 && addr ==  addr_size - 1)begin
			addr <= {ADDR_WIDTH{1'b0}};
		end
		else if( app_rdwr_en == 1'b1 )begin
			addr <= addr + 1'b1;
		end
		else;
	end

	// always@( posedge clk_ddr3 )begin	
		// if( rst_n_ddr == 1'b0 )begin
			// app_en_rd <= 1'b0;
		// end
		// else if( rd_flag == 1'b1 )begin
			// if( app_en_rd == 1'b1 && app_rdy == 1'b1 && addr == addr_size - 1'b1 )begin
				// app_en_rd <= 1'b0;
			// end
			// else if( addr >= addr_size )begin
				// app_en_rd <= 1'b0;
			// end
			// else if( fifo_rd_prog_full == 1'b1 )begin
				// app_en_rd <= 1'b0;
			// end
			// else begin
				// app_en_rd <= 1'b1;
			// end		
		// end
		// else begin
			// app_en_rd <= 1'b0;
		// end
	// end

	assign app_addr = {addr[0+:25],3'b000};
	
	assign app_en_wr = ~rd_flag & ~fifo_wr_empty & app_wdf_rdy & app_rdy;
	
	assign app_cmd = ( rd_flag == 1'b1 ) ? 3'b001 : 3'b000;

	assign app_en = app_en_wr | app_en_rd ;
	
	assign fifo_rd_din 		= app_rd_data;
	assign fifo_rd_wr_en 	= app_rd_data_valid;
	assign app_wdf_end 		= app_en_wr;
	assign app_wdf_wren 	= app_en_wr;
	
	assign fifo_wr_rd_en	= app_en_wr;
	assign app_wdf_data		= {32'd0,fifo_wr_dout};
	
	assign dout = fifo_rd_dout;
	assign fifo_rd_rd_en = dout_rd_en;
	assign dout_empty = fifo_rd_empty;
	assign dout_alempty = fifo_rd_almost_empty;
	
	
	fifo_async_1024x32 fifo_wr(
		.wr_clk 		( clk 					),
		.rd_clk 		( clk_ddr3 				),
		.rst 			(~rst_n					),
		// .rst 			(1'b0					),
		.din 			( fifo_wr_din			),
		.wr_en 			( fifo_wr_wr_en 		),
		.rd_en 			( fifo_wr_rd_en 		),
		.dout			( fifo_wr_dout			),
		.full			( fifo_wr_full			),
		.almost_full 	( fifo_wr_almost_full 	),
		.prog_full 		( fifo_wr_prog_full 	),
		.empty 			( fifo_wr_empty 		),
		.almost_empty 	( fifo_wr_almost_empty 	)
	);
	
	fifo_async_1024x32 fifo_rd(
		.wr_clk 		( clk_ddr3				),
		.rd_clk 		( clk	 				),
		.rst 			(~rst_n					),
		.din 			( fifo_rd_din			),
		.wr_en 			( fifo_rd_wr_en 		),
		.rd_en 			( fifo_rd_rd_en 		),
		.dout			( fifo_rd_dout			),
		.full			( fifo_rd_full			),
		.almost_full 	( fifo_rd_almost_full 	),
		.prog_full 		( fifo_rd_prog_full 	),
		.empty 			( fifo_rd_empty 		),
		.almost_empty 	( fifo_rd_almost_empty 	)
	);
	
	wire[12-1:0]device_temp;

	mig_7series_0 ddr3_0 (
		// Memory interface ports
		.ddr3_addr                	( ddr3_addr     			),  // output [13:0]	ddr3_addr
		.ddr3_ba                  	( ddr3_ba					),  // output [2:0]		ddr3_ba
		.ddr3_cas_n               	( ddr3_cas_n				),  // output			ddr3_cas_n
		.ddr3_ck_n                	( ddr3_ck_n					),  // output [0:0]		ddr3_ck_n
		.ddr3_ck_p                	( ddr3_ck_p					),  // output [0:0]		ddr3_ck_p
		.ddr3_cke                 	( ddr3_cke					),  // output [0:0]		ddr3_cke
		.ddr3_ras_n               	( ddr3_ras_n				),  // output			ddr3_ras_n
		.ddr3_reset_n             	( ddr3_reset_n				),  // output			ddr3_reset_n
		.ddr3_we_n                	( ddr3_we_n					),  // output			ddr3_we_n
		.ddr3_dq                  	( ddr3_dq					),  // inout [31:0]		ddr3_dq
		.ddr3_dqs_n               	( ddr3_dqs_n				),  // inout [3:0]		ddr3_dqs_n
		.ddr3_dqs_p               	( ddr3_dqs_p				),  // inout [3:0]		ddr3_dqs_p
		.init_calib_complete      	( init_done					),  // output			init_calib_completee
		.ddr3_cs_n                	( ddr3_cs_n					),  // output [0:0]		ddr3_cs_n
		.ddr3_dm                  	( ddr3_dm					),  // output [3:0]		ddr3_dm
		.ddr3_odt                 	( ddr3_odt					),  // output [0:0]		ddr3_odt
		// Application interface ports                              
		.app_addr           		( app_addr					),  // input [27:0]		app_addr
		.app_cmd            		( app_cmd					),  // input [2:0]		app_cmd
		.app_en             		( app_en					),  // input			app_en
		.app_wdf_data       		( app_wdf_data				),  // input [63:0]		app_wdf_data
		.app_wdf_end        		( app_wdf_end				),  // input			app_wdf_end
		.app_wdf_wren       		( app_wdf_wren				),  // input			app_wdf_wren
		.app_rd_data        		( app_rd_data				),  // output [63:0]	app_rd_data
		.app_rd_data_end    		( app_rd_data_end			),  // output			app_rd_data_end
		.app_rd_data_valid  		( app_rd_data_valid			),  // output			app_rd_data_valid
		.app_rdy            		( app_rdy					),  // output			app_rdy
		.app_wdf_rdy        		( app_wdf_rdy				),  // output			app_wdf_rdy
		.app_sr_req         		( 1'b0						),  // input			app_sr_req
		.app_ref_req        		( 1'b0						),  // input			app_ref_req
		.app_zq_req         		( 1'b0 						),  // input			app_zq_req
		.app_sr_active      		( app_sr_active				),  // output			app_sr_active
		.app_ref_ack        		( app_ref_ack				),  // output			app_ref_ack
		.app_zq_ack         		( app_zq_ack				),  // output			app_zq_ack
		.ui_clk             		( clk_ddr3					),  // output			ui_clk
		.ui_clk_sync_rst    		( ddr_ui_rst				),  // output			ui_clk_sync_rst
		.app_wdf_mask       		( 8'd0						),  // input [7:0]		app_wdf_mask
		.device_temp				( device_temp				),  //  
		.device_temp_i				( 12'd0						),  //  
		// System Clock Ports	                                    
		.sys_clk_i               	( ddr3_sys_clk				),  // input			sys_clk_i
		.sys_rst                 	( 1'b1						) 	// input sys_rst low active
    );
	
	reset_cross c0_cross(
		.clk_i			( clk			),
		.clk_o			( clk_ddr3		),
		.din_rst_n		( rst_n			),
		.din_rst_n_vld	(~rst_n			),
		.dout_rst_n		( rst_n_ddr		) 
	);
		
	wire ddr3_wr_full_ui = rd_flag && fifo_wr_rd_en;
	
	data_cross#(	
		.DATA_WIDTH		( 1					),
		.DEFAULT_VALUE	( 1'b0				)
	)c1_cross(
		.clk_i			( clk_ddr3			),
		.clk_o			( clk				),
		.din			( ddr3_wr_full_ui	),
		.din_vld		( ddr3_wr_full_ui	),
		.dout			( ddr3_wr_full		),
		.dout_vld		( 					)
	);
	
	ila_fifo_ddr ila_0(
		.clk 		( clk_ddr3				),
		.probe0		( wr_flag				),
		.probe1		( addr					),
		.probe2		( app_en_rd				),
		.probe3		( app_en_wr				),
		.probe4		( app_rdy				),
		.probe5		( init_done				)
	);
	
	
	
	endmodule
