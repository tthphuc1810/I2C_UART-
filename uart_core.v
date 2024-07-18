
//------------------------------------------------------------
//-- UART CORE
//------------------------------------------------------------

`include "n2v_define.v"
module uart_core (/*AUTOARG*/
   // Outputs
   uart_tx,  
   `ifdef  UART_COMBINE_INTERRUPT  uart_if,
   `else   uart_fif ,uart_oif,uart_pif, uart_rif,uart_tif,
   `endif
   rx_rts, prdata,
   // Inputs
   uart_rx, uart_cts, pwrite, pwdata, psel, prst_n, penable, pclk,
   paddr
   );
  
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output [31:0]		prdata;			// From apb of uart_apb.v
  output		rx_rts;			// From receiver of uart_receiver.v
  `ifdef UART_COMBINE_INTERRUPT
  output		uart_if;		// From apb of uart_apb.v
  `else 
  output		uart_fif;		// From apb of uart_apb.v  
  output		uart_oif;		// From apb of uart_apb.v
  output		uart_pif;		// From apb of uart_apb.v
  output		uart_rif;		// From apb of uart_apb.v
  output		uart_tif;		// From apb of uart_apb.v
  `endif
  output		uart_tx;		// From trans of uart_transmitter.v
  // End of automatics
  
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input [31:0]		paddr;			// To apb of uart_apb.v
  input			pclk;			// To apb of uart_apb.v, ...
  input			penable;		// To apb of uart_apb.v
  input			prst_n;		// To apb of uart_apb.v, ...
  input			psel;			// To apb of uart_apb.v
  input [31:0]		pwdata;			// To apb of uart_apb.v
  input			pwrite;			// To apb of uart_apb.v
  input			uart_cts;		// To trans of uart_transmitter.v
  input			uart_rx;		// To receiver of uart_receiver.v
  // End of automatics
  
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire			apb_af;			// From apb of uart_apb.v
  wire [7:0]		apb_brg;		// From apb of uart_apb.v
  wire			apb_bsel;		// From apb of uart_apb.v
  wire			apb_crx;		// From apb of uart_apb.v
  wire			apb_d9;			// From apb of uart_apb.v
  wire [7:0]		apb_data;		// From apb of uart_apb.v
  wire			apb_en;			// From apb of uart_apb.v
  wire			apb_rxff_rd;		// From apb of uart_apb.v
  wire [1:0]		apb_rxt;		// From apb of uart_apb.v
  wire			apb_tx_en;		// From apb of uart_apb.v
  wire			brg_rx_shift;		// From baud of uart_baud.v
  wire			brg_tx_shift;		// From baud of uart_baud.v
  wire			rx_busy;		// From receiver of uart_receiver.v
  wire [7:0]		rx_data;		// From receiver of uart_receiver.v
  wire			rx_fe;			// From receiver of uart_receiver.v
  wire			rx_ov;			// From receiver of uart_receiver.v
  wire			rx_pe;			// From receiver of uart_receiver.v
  wire			rx_rxf;			// From receiver of uart_receiver.v
  wire			rx_rxne;		// From receiver of uart_receiver.v
  wire			tx_busy;		// From trans of uart_transmitter.v
  wire			tx_txff_rd;		// From trans of uart_transmitter.v
  // End of automatics
  
  uart_apb apb(/*AUTOINST*/
	       // Outputs
	       .apb_af			(apb_af),
	       .apb_brg			(apb_brg[7:0]),
	       .apb_bsel		(apb_bsel),
	       .apb_crx			(apb_crx),
	       .apb_d9			(apb_d9),
	       .apb_data		(apb_data[7:0]),
	       .apb_en			(apb_en),
	       .apb_rxff_rd		(apb_rxff_rd),
	       .apb_rxt			(apb_rxt[1:0]),
	       .apb_tx_en		(apb_tx_en),
	       .prdata			(prdata[31:0]),
	       `ifdef UART_COMBINE_INTERRUPT
	       .uart_if			(uart_if),
	       `else
	       .uart_fif		(uart_fif),
	       .uart_oif		(uart_oif),
	       .uart_pif		(uart_pif),
	       .uart_rif		(uart_rif),
	       .uart_tif		(uart_tif),
	       `endif
	       // Inputs
	       .paddr			(paddr[31:0]),
	       .pclk			(pclk),
	       .penable			(penable),
	       .prst_n		(prst_n),
	       .psel			(psel),
	       .pwdata			(pwdata[31:0]),
	       .pwrite			(pwrite),
	       .rx_busy			(rx_busy),
	       .rx_data			(rx_data[7:0]),
	       .rx_fe			(rx_fe),
	       .rx_ov			(rx_ov),
	       .rx_pe			(rx_pe),
	       .rx_rxf			(rx_rxf),
	       .tx_busy			(tx_busy),
	       .tx_txff_rd		(tx_txff_rd),
	       .rx_rxne			(rx_rxne));
  
  uart_baud baud(/*AUTOINST*/
		 // Outputs
		 .brg_tx_shift		(brg_tx_shift),
		 .brg_rx_shift		(brg_rx_shift),
		 // Inputs
		 .pclk			(pclk),
		 .prst_n		(prst_n),
		 .apb_en		(apb_en),
		 .apb_bsel		(apb_bsel),
		 .apb_brg		(apb_brg[7:0]));
  
  uart_transmitter trans(/*AUTOINST*/
			 // Outputs
			 .tx_txff_rd		(tx_txff_rd),
			 .uart_tx		(uart_tx),
			 .tx_busy		(tx_busy),
			 // Inputs
			 .pclk			(pclk),
			 .prst_n		(prst_n),
			 .brg_tx_shift		(brg_tx_shift),
			 .apb_d9		(apb_d9),
			 .apb_af		(apb_af),
			 .apb_tx_en		(apb_tx_en),
			 .apb_data		(apb_data[7:0]),
			 .uart_cts		(uart_cts));
  
  uart_receiver receiver (/*AUTOINST*/
			  // Outputs
			  .rx_rts		(rx_rts),
			  .rx_rxne		(rx_rxne),
			  .rx_fe		(rx_fe),
			  .rx_pe		(rx_pe),
			  .rx_ov		(rx_ov),
			  .rx_rxf		(rx_rxf),
			  .rx_data		(rx_data[7:0]),
			  .rx_busy		(rx_busy),
			  // Inputs
			  .apb_rxt		(apb_rxt[1:0]),
			  .pclk			(pclk),
			  .prst_n		(prst_n),
			  .apb_bsel		(apb_bsel),
			  .apb_d9		(apb_d9),
			  .apb_en		(apb_en),
			  .apb_crx		(apb_crx),
			  .apb_af		(apb_af),
			  .apb_rxff_rd		(apb_rxff_rd),
			  .brg_rx_shift		(brg_rx_shift),
			  .uart_rx		(uart_rx));

  
endmodule
