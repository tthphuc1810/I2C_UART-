

//------------------------------------------------------------
//-- I2C CORE
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_core (/*AUTOARG*/
   // Outputs
   prdata, i2c_if,
   // Inouts
   sda, scl,
   // Inputs
   pwrite, pwdata, psel, prst_n, penable, pclk, paddr
   );

/*AUTOINPUT*/
// Beginning of automatic inputs (from unused autoinst inputs)
input [7:0]		paddr;			// To ia of i2c_apb.v
input			pclk;			// To ii of i2c_interface.v, ...
input			penable;		// To ia of i2c_apb.v
input			prst_n;			// To ii of i2c_interface.v, ...
input			psel;			// To ia of i2c_apb.v
input [31:0]		pwdata;			// To ia of i2c_apb.v
input			pwrite;			// To ia of i2c_apb.v
// End of automatics

/*AUTOOUTPUT*/
// Beginning of automatic outputs (from unused autoinst outputs)
output			i2c_if;			// From ia of i2c_apb.v
output [31:0]		prdata;			// From ia of i2c_apb.v
// End of automatics

inout sda, scl;

/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire [6:0]		apb_add;		// From ia of i2c_apb.v
wire			apb_crx;		// From ia of i2c_apb.v
wire [1:0]		apb_csel;		// From ia of i2c_apb.v
wire			apb_ctx;		// From ia of i2c_apb.v
wire [7:0]		apb_data;		// From ia of i2c_apb.v
wire			apb_en;			// From ia of i2c_apb.v
wire			apb_ms;			// From ia of i2c_apb.v
wire			apb_rs;			// From ia of i2c_apb.v
wire			apb_rw;			// From ia of i2c_apb.v
wire			apb_rxff_rd;		// From ia of i2c_apb.v
wire			apb_sp;			// From ia of i2c_apb.v
wire [6:0]		apb_tadd;		// From ia of i2c_apb.v
wire			apb_txff_wr;		// From ia of i2c_apb.v
wire			i_clk;			// From ic of i2c_clock.v
wire			i_clock_en;		// From ii of i2c_interface.v
wire			i_clock_stop;		// From ii of i2c_interface.v
wire			i_mrs;			// From ii of i2c_interface.v
wire			i_rx_busy;		// From ii of i2c_interface.v
wire			i_rxff_wr;		// From ii of i2c_interface.v
wire			i_tx_busy;		// From ii of i2c_interface.v
wire			i_txff_rd;		// From ii of i2c_interface.v
wire [7:0]		rxff_data;		// From ir of i2c_rxff.v
wire [7:0]		rxff_din;		// From ii of i2c_interface.v
wire			rxff_ov;		// From ir of i2c_rxff.v
wire			rxff_rxne;		// From ir of i2c_rxff.v
wire [7:0]		txff_data;		// From it of i2c_txff.v
wire			txff_empty;		// From it of i2c_txff.v
wire			txff_txnf;		// From it of i2c_txff.v
// End of automatics

i2c_interface 	ii(/*AUTOINST*/
		   // Outputs
		   .i_rx_busy		(i_rx_busy),
		   .i_tx_busy		(i_tx_busy),
		   .i_txff_rd		(i_txff_rd),
		   .i_rxff_wr		(i_rxff_wr),
		   .rxff_din		(rxff_din[7:0]),
		   .i_clock_en		(i_clock_en),
		   .i_mrs		(i_mrs),
		   .i_clock_stop	(i_clock_stop),
		   // Inouts
		   .sda			(sda),
		   .scl			(scl),
		   // Inputs
		   .pclk		(pclk),
		   .prst_n		(prst_n),
		   .i_clk		(i_clk),
		   .txff_data		(txff_data[7:0]),
		   .apb_en		(apb_en),
		   .apb_ms		(apb_ms),
		   .apb_sp		(apb_sp),
		   .apb_rs		(apb_rs),
		   .apb_rw		(apb_rw),
		   .apb_csel		(apb_csel[1:0]),
		   .apb_add		(apb_add[6:0]),
		   .apb_tadd		(apb_tadd[6:0]),
		   .rxff_ov		(rxff_ov),
		   .txff_empty		(txff_empty));

i2c_apb			ia(/*AUTOINST*/
			   // Outputs
			   .prdata		(prdata[31:0]),
			   .apb_ctx		(apb_ctx),
			   .apb_crx		(apb_crx),
			   .apb_ms		(apb_ms),
			   .apb_en		(apb_en),
			   .apb_add		(apb_add[6:0]),
			   .apb_rw		(apb_rw),
			   .apb_sp		(apb_sp),
			   .apb_rs		(apb_rs),
			   .apb_data		(apb_data[7:0]),
			   .apb_csel		(apb_csel[1:0]),
			   .apb_tadd		(apb_tadd[6:0]),
			   .apb_txff_wr		(apb_txff_wr),
			   .apb_rxff_rd		(apb_rxff_rd),
			   .i2c_if		(i2c_if),
			   // Inputs
			   .prst_n		(prst_n),
			   .pclk		(pclk),
			   .psel		(psel),
			   .penable		(penable),
			   .pwrite		(pwrite),
			   .paddr		(paddr[7:0]),
			   .pwdata		(pwdata[31:0]),
			   .rxff_data		(rxff_data[7:0]),
			   .rxff_ov		(rxff_ov),
			   .i_rx_busy		(i_rx_busy),
			   .i_tx_busy		(i_tx_busy),
			   .rxff_rxne		(rxff_rxne),
			   .txff_txnf		(txff_txnf),
			   .i_mrs		(i_mrs));

i2c_rxff		ir(/*AUTOINST*/
			   // Outputs
			   .rxff_data		(rxff_data[7:0]),
			   .rxff_rxne		(rxff_rxne),
			   .rxff_ov		(rxff_ov),
			   // Inputs
			   .rxff_din		(rxff_din[7:0]),
			   .pclk		(pclk),
			   .prst_n		(prst_n),
			   .apb_crx		(apb_crx),
			   .i_rxff_wr		(i_rxff_wr),
			   .apb_rxff_rd		(apb_rxff_rd));

i2c_txff		it(/*AUTOINST*/
			   // Outputs
			   .txff_data		(txff_data[7:0]),
			   .txff_txnf		(txff_txnf),
			   .txff_empty		(txff_empty),
			   // Inputs
			   .apb_data		(apb_data[7:0]),
			   .pclk		(pclk),
			   .prst_n		(prst_n),
			   .apb_ctx		(apb_ctx),
			   .i_txff_rd		(i_txff_rd),
			   .apb_txff_wr		(apb_txff_wr));

i2c_clock		ic(/*AUTOINST*/
			   // Outputs
			   .i_clk		(i_clk),
			   // Inputs
			   .apb_csel		(apb_csel[1:0]),
			   .pclk		(pclk),
			   .prst_n		(prst_n),
			   .i_clock_en		(i_clock_en),
			   .i_clock_stop	(i_clock_stop));



endmodule  
  
