
//------------------------------------------------------------
//-- I2C-UART CORE
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_uart (/*AUTOARG*/
   // Outputs
   uart_tx, 
   `ifdef  UART_COMBINE_INTERRUPT  uart_if,
   `else   uart_fif ,uart_oif,uart_pif, uart_rif,uart_tif,
   `endif
   rx_rts, i2c_if,
   // Inputs
   uart_rx, uart_cts, prst_n, pclk, data_wr, data_sel, data_in, apb_we, apb_re,
   //Inouts
   sda, scl
   );
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input			apb_re;			// To am of apb_master.v
  input			apb_we;			// To am of apb_master.v
  input [7:0]		data_in;		// To am of apb_master.v
  input			data_sel;		// To am of apb_master.v
  input			data_wr;		// To am of apb_master.v
  input			pclk;			// To am of apb_master.v, ...
  input			prst_n;			// To am of apb_master.v, ...
  input			uart_cts;		// To uc of uart_core.v
  input			uart_rx;		// To uc of uart_core.v
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output		i2c_if;			// From ic of i2c_core.v
  output		rx_rts;			// From uc of uart_core.v
  `ifdef  UART_COMBINE_INTERRUPT
  output		uart_if;		// From uc of uart_core.v
  `else
  output		uart_fif;		// From uc of uart_core.v 
  output		uart_oif;		// From uc of uart_core.v
  output		uart_pif;		// From uc of uart_core.v
  output		uart_rif;		// From uc of uart_core.v
  output		uart_tif;		// From uc of uart_core.v
  `endif
  output		uart_tx;		// From uc of uart_core.v
  // End of automatics
  //INOUTS
  inout			scl;			// To/From ic of i2c_core.v
  inout			sda;			// To/From ic of i2c_core.v
  // End of automatics
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire [31:0]		paddr;			// From am of apb_master.v
  wire			penable;		// From am of apb_master.v
  wire [31:0]		prdata;			// From ic of i2c_core.v, ...
  wire			psel;			// From am of apb_master.v
  wire [31:0]		pwdata;			// From am of apb_master.v
  wire			pwrite;			// From am of apb_master.v
  
  
  
  apb_master apb_m(/*AUTOINST*/
		// Outputs
		.pwrite			(pwrite),
		.penable		(penable),
		.psel			(psel),
		.paddr			(paddr[31:0]),
		.pwdata			(pwdata[31:0]),
		// Inputs
		.pclk			(pclk),
		.prst_n			(prst_n),
		.data_sel		(data_sel),
		.data_wr		(data_wr),
		.data_in		(data_in[7:0]),
		.apb_we			(apb_we),
		.apb_re			(apb_re),
		.prdata			(prdata[31:0])
		);
  
  i2c_core i2c_m(/*AUTOINST*/
	      // Outputs
	      .i2c_if			(i2c_if),
	      .prdata			(prdata[31:0]),
	      // Inouts
	      .sda			(sda),
	      .scl			(scl),
	      // Inputs
	      .paddr			(paddr[7:0]),
	      .pclk			(pclk),
	      .penable			(penable),
	      .prst_n			(prst_n),
	      .psel			(psel),
	      .pwdata			(pwdata[31:0]),
	      .pwrite			(pwrite));
  
  uart_core uc(/*AUTOINST*/
	       // Outputs
	       .prdata			(prdata[31:0]),
	       .rx_rts			(rx_rts),
	       `ifdef  UART_COMBINE_INTERRUPT
	       .uart_if			(uart_if),
	       `else
	       .uart_fif		(uart_fif),
	       .uart_oif		(uart_oif),
	       .uart_pif		(uart_pif),
	       .uart_rif		(uart_rif),
	       .uart_tif		(uart_tif),
	       `endif
	       .uart_tx			(uart_tx),
	       // Inputs
	       .paddr			(paddr[31:0]),
	       .pclk			(pclk),
	       .penable			(penable),
	       .prst_n			(prst_n),
	       .psel			(psel),
	       .pwdata			(pwdata[31:0]),
	       .pwrite			(pwrite),
	       .uart_cts		(uart_cts),
	       .uart_rx			(uart_rx));
  
endmodule