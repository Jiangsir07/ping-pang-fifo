`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/05/23 16:04:27
// Design Name: 
// Module Name: tb_ddr_pingpang
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_ddr_pingpang();

	reg rst_n;
	
	reg clk =0;
	always #5 clk = ~clk;
	
	reg clk_200m =0;
	always #2.5 clk_200m = ~clk_200m;
	
	initial begin
		rst_n = 0;
		#105560
		rst_n = 1;
	end

	initial begin
		#100 force u3.addr_size = 32'h2000; 
	end


	wire 	[13:0]			ddr3_0_addr   			;
	wire 	[2:0]			ddr3_0_ba		 		;
	wire 					ddr3_0_cas_n	 		;
	wire 	[0:0]			ddr3_0_ck_n	 			;
	wire 	[0:0]			ddr3_0_ck_p	 			;
	wire 	[0:0]			ddr3_0_cke	 			;
	wire 					ddr3_0_ras_n	 		;
	wire 					ddr3_0_reset_n 			;
	wire 					ddr3_0_we_n	 			;
	wire 	[7:0]			ddr3_0_dq		 		;
	wire 	[0:0]			ddr3_0_dqs_n	 		;
	wire 	[0:0]			ddr3_0_dqs_p	 		;
	wire 	[0:0]			init_0_done	 			;
	wire 	[0:0]			ddr3_0_cs_n	 			;
	wire 	[0:0]			ddr3_0_dm		 		;
	wire                    ddr3_0_odt				;
	wire                    ddr3_0_sys_clk			;
                                         
	wire 	[13:0]			ddr3_1_addr   			;
	wire 	[2:0]			ddr3_1_ba		 		;
	wire 					ddr3_1_cas_n	 		;
	wire 	[0:0]			ddr3_1_ck_n	 			;
	wire 	[0:0]			ddr3_1_ck_p	 			;
	wire 	[0:0]			ddr3_1_cke	 			;
	wire 					ddr3_1_ras_n	 		;
	wire 					ddr3_1_reset_n 			;
	wire 					ddr3_1_we_n	 			;
	wire 	[7:0]			ddr3_1_dq		 		;
	wire 	[0:0]			ddr3_1_dqs_n	 		;
	wire 	[0:0]			ddr3_1_dqs_p	 		;
	wire 	[0:0]			init_1_done	 			;
	wire 	[0:0]			ddr3_1_cs_n	 			;
	wire 	[0:0]			ddr3_1_dm		 		;
	wire                    ddr3_1_odt				;
	wire                   	ddr3_1_sys_clk			;

	wire 			initial_done = init_0_done && init_1_done;
	
	//写数据
	wire 			data_merge_rd_en		;
	wire [32-1:0]	data_merge				;
	wire 			data_merge_empty		;
	wire 			data_merge_alempty   	;
	wire 			data_merge_full		   	;
	wire 			data_merge_prog_full   	;

	reg 			fifo_in_vld;
	reg [31:0] 		fifo_in,fifo_in_tmp;
	always @(posedge clk)begin
		if(rst_n == 1'b0)begin
			fifo_in_vld <= 1'b0;
			fifo_in <= 32'd0;
			fifo_in_tmp <= 32'd0;
		end
		else if(initial_done) begin
			if(data_merge_prog_full == 1'b0)begin
				fifo_in_vld <= 1'b1;
				fifo_in_tmp <= fifo_in_tmp + 1;
				fifo_in <= fifo_in_tmp;
			end
			else begin
				fifo_in_vld <= 1'b0;
				fifo_in_tmp <= fifo_in_tmp;
				fifo_in <= fifo_in;
			end
		end
		else begin
			fifo_in_vld <= 1'b0;
			fifo_in <= 32'd0;
			fifo_in_tmp <= 32'd0;
		end
	end
	
	wire dout_empty,dout_alempty;
	reg dout_rd_en;
	wire [31:0] dout;
	always @(posedge clk)begin
		if(rst_n == 1'b0)begin
			dout_rd_en <= 1'b0;
		end
		else if(dout_alempty == 1'b0)begin
			dout_rd_en <= 1'b1;
		end
		else if(dout_rd_en == 1'b1)begin
			dout_rd_en <= 1'b0;
		end
		else begin
			dout_rd_en <= ~dout_empty;
		end
	end


	fifo_async_1024x32 fifo_rd(
		.wr_clk 		( clk					),
		.rd_clk 		( clk	 				),
		.rst 			(~rst_n					),
		.din 			( fifo_in				),
		.wr_en 			( fifo_in_vld 			),
		.rd_en 			( data_merge_rd_en 		),
		.dout			( data_merge			),
		.full			( data_merge_full		),
		.almost_full 	(  						),
		.prog_full 		( data_merge_prog_full	),
		.empty 			( data_merge_empty 		),
		.almost_empty 	( data_merge_alempty 	)
	);


	ddr3_pingpang_1 u3(
		.clk				( clk					),
		.rst_n				( rst_n					),
		
		.din				( data_merge			),
		.din_rd_en			( data_merge_rd_en		),
		.din_empty			( data_merge_empty		),
		.din_alempty		( data_merge_alempty	),
		
		.dout				( dout					),
		.dout_rd_en			( dout_rd_en			),
		.dout_empty			( dout_empty			),
		.dout_alempty		( dout_alempty			),
	
		.ddr3_0_addr   		( ddr3_0_addr   		),
		.ddr3_0_ba			( ddr3_0_ba		 		),
		.ddr3_0_cas_n		( ddr3_0_cas_n	 		),
		.ddr3_0_ck_n		( ddr3_0_ck_n	 		),
		.ddr3_0_ck_p		( ddr3_0_ck_p	 		),
		.ddr3_0_cke			( ddr3_0_cke	 		),
		.ddr3_0_ras_n		( ddr3_0_ras_n	 		),
		.ddr3_0_reset_n		( ddr3_0_reset_n 		),
		.ddr3_0_we_n		( ddr3_0_we_n	 		),
		.ddr3_0_dq			( ddr3_0_dq		 		),
		.ddr3_0_dqs_n		( ddr3_0_dqs_n	 		),
		.ddr3_0_dqs_p		( ddr3_0_dqs_p	 		),
		.init_0_done		( init_0_done	 		),
		.ddr3_0_cs_n		( ddr3_0_cs_n	 		),
		.ddr3_0_dm			( ddr3_0_dm		 		),
		.ddr3_0_odt			( ddr3_0_odt			),
		.ddr3_0_sys_clk		( clk_200m				),
		
		.ddr3_1_addr   		( ddr3_1_addr   		),
		.ddr3_1_ba			( ddr3_1_ba		 		),
		.ddr3_1_cas_n		( ddr3_1_cas_n	 		),
		.ddr3_1_ck_n		( ddr3_1_ck_n	 		),
		.ddr3_1_ck_p		( ddr3_1_ck_p	 		),
		.ddr3_1_cke			( ddr3_1_cke	 		),
		.ddr3_1_ras_n		( ddr3_1_ras_n	 		),
		.ddr3_1_reset_n		( ddr3_1_reset_n 		),
		.ddr3_1_we_n		( ddr3_1_we_n	 		),
		.ddr3_1_dq			( ddr3_1_dq		 		),
		.ddr3_1_dqs_n		( ddr3_1_dqs_n	 		),
		.ddr3_1_dqs_p		( ddr3_1_dqs_p	 		),
		.init_1_done		( init_1_done	 		),
		.ddr3_1_cs_n		( ddr3_1_cs_n	 		),
		.ddr3_1_dm			( ddr3_1_dm		 		),
		.ddr3_1_odt			( ddr3_1_odt			),
		.ddr3_1_sys_clk		( clk_200m				)
	);

	//读数据校验
	reg [31:0] ddr_dout ;
	always @(posedge clk)begin
		if( !rst_n )begin
			ddr_dout <= 32'd0;
		end
		else if( dout_rd_en )begin
			ddr_dout <= dout;
		end
	end
	
	reg error;
	always @(posedge clk)begin
		if( !rst_n )begin
			error <= 1'b0;
		end
		else if( dout_rd_en && ddr_dout + 32'd1 != dout && dout != 32'd0)begin
			error <= 1'b1;
		end
		else begin
			error <= 1'b0;
		end
	end
	
	
	//SV DDR model
	ddr3_model u_comp_ddr3_0(
	   .rst_n   (ddr3_0_reset_n),					  
	   .ck      (ddr3_0_ck_p),					  
	   .ck_n    (ddr3_0_ck_n),					  
	   .cke     (ddr3_0_cke),					  
	   .cs_n    (ddr3_0_cs_n),					  
	   .ras_n   (ddr3_0_ras_n),					  
	   .cas_n   (ddr3_0_cas_n),					  
	   .we_n    (ddr3_0_we_n),
	   .dm_tdqs ({ddr3_0_dm,ddr3_0_dm}),
	   .ba      (ddr3_0_ba),
	   .addr    (ddr3_0_addr),
	   .dq      ({ddr3_0_dq[7:0],ddr3_0_dq[7:0]}),
	   .dqs     ({ddr3_0_dqs_p,ddr3_0_dqs_p}),
	   .dqs_n   ({ddr3_0_dqs_n,ddr3_0_dqs_n}),
	   .tdqs_n  (),
	   .odt     (ddr3_0_odt)
	);
	
	ddr3_model u_comp_ddr3_1(
	   .rst_n   (ddr3_1_reset_n),					  
	   .ck      (ddr3_1_ck_p),					  
	   .ck_n    (ddr3_1_ck_n),					  
	   .cke     (ddr3_1_cke),					  
	   .cs_n    (ddr3_1_cs_n),					  
	   .ras_n   (ddr3_1_ras_n),					  
	   .cas_n   (ddr3_1_cas_n),					  
	   .we_n    (ddr3_1_we_n),
	   .dm_tdqs ({ddr3_1_dm,ddr3_1_dm}),
	   .ba      (ddr3_1_ba),
	   .addr    (ddr3_1_addr),
	   .dq      ({ddr3_1_dq[7:0],ddr3_1_dq[7:0]}),
	   .dqs     ({ddr3_1_dqs_p,ddr3_1_dqs_p}),
	   .dqs_n   ({ddr3_1_dqs_n,ddr3_1_dqs_n}),
	   .tdqs_n  (),
	   .odt     (ddr3_1_odt)
	);


endmodule
