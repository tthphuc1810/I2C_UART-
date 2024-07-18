`include "n2v_define.v"
module i2c_uart_fpga_quartus (/*AUTOARG*/
   // Outputs
   uart_tx,  
   `ifdef  UART_COMBINE_INTERRUPT  uart_if,
   `else   uart_fif ,uart_oif,uart_pif, uart_rif,uart_tif,
   `endif
   rx_rts, i2c_if, i2c_i2c_if, i2c_prdata,
   // Inputs
   uart_rx, uart_cts, prst_n, pclk, i2c_data_wr, i2c_data_sel,
   data_in_sel, i2c_apb_we, i2c_apb_re, data_wr, data_sel, data_fpga,
   apb_we, apb_re 
   );
  /*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input			apb_re;			// To n2v_m of i2c_uart.v
  input			apb_we;			// To n2v_m of i2c_uart.v
  input [7:0]	data_fpga;		// To n2v_m of i2c_uart.v
  input			data_sel;		// To n2v_m of i2c_uart.v
  input			data_wr;		// To n2v_m of i2c_uart.v
  input			i2c_apb_re;		// To i2c_f of i2c_fpga.v
  input			i2c_apb_we;		// To i2c_f of i2c_fpga.v
  input 		data_in_sel;		// To i2c_f of i2c_fpga.v
  input			i2c_data_sel;		// To i2c_f of i2c_fpga.v
  input			i2c_data_wr;		// To i2c_f of i2c_fpga.v
  input			pclk;			// To n2v_m of i2c_uart.v, ...
  input			prst_n;			// To n2v_m of i2c_uart.v, ...
  input			uart_cts;		// To n2v_m of i2c_uart.v
  input			uart_rx;		// To n2v_m of i2c_uart.v
  // End of automatics
  /*AUTOOUTPUT*/
  // Beginning of automatic outputs (from unused autoinst outputs)
  output [31:0]		i2c_prdata;		// From i2c_f of i2c_fpga.v
  output		i2c_i2c_if;		// From i2c_f of i2c_fpga.v
  output		i2c_if;			// From n2v_m of i2c_uart.v
  output		rx_rts;			// From n2v_m of i2c_uart.v
  `ifdef  UART_COMBINE_INTERRUPT
  output		uart_if;		// From n2v_m of i2c_uart.v
  `else
  output		uart_fif;		// From n2v_m of i2c_uart.v
  output		uart_oif;		// From n2v_m of i2c_uart.v
  output		uart_pif;		// From n2v_m of i2c_uart.v
  output		uart_rif;		// From n2v_m of i2c_uart.v
  output		uart_tif;		// From n2v_m of i2c_uart.v
  `endif
  output		uart_tx;		// From n2v_m of i2c_uart.v
  
  // End of automatics
  /*AUTOWIRE*/
  // Beginning of automatic wires (for undeclared instantiated-module outputs)
  wire			scl;			// To/From n2v_m of i2c_uart.v, ...
  wire			sda;			// To/From n2v_m of i2c_uart.v, ...
  // End of automatics
  wire [7:0] data_in, i2c_data_in;
  
  assign data_in = (data_in_sel)?data_fpga:8'b0;
  assign i2c_data_in = (~data_in_sel)?data_fpga:8'b0;
  
  i2c_uart i_u(/*AUTOINST*/
		   // Outputs
		   .i2c_if		(i2c_if),
		   .rx_rts		(rx_rts),
		   `ifdef  UART_COMBINE_INTERRUPT
		   .uart_if		(uart_if),
		   `else
		   .uart_fif		(uart_fif),		   
		   .uart_oif		(uart_oif),
		   .uart_pif		(uart_pif),
		   .uart_rif		(uart_rif),
		   .uart_tif		(uart_tif),
		   `endif
		   .uart_tx		(uart_tx),
		   // Inouts
		   .scl			(scl),
		   .sda			(sda),
		   // Inputs
		   .apb_re		(apb_re),
		   .apb_we		(apb_we),
		   .data_in		(data_in[7:0]),
		   .data_sel		(data_sel),
		   .data_wr		(data_wr),
		   .pclk		(pclk),
		   .prst_n		(prst_n),
		   .uart_cts		(uart_cts),
		   .uart_rx		(uart_rx));
  i2c_fpga i2c_f(/*AUTOINST*/
		 // Outputs
		 .prdata 		(i2c_prdata),
		 .i2c_if		(i2c_i2c_if),
		 // Inouts
		 .sda			(sda),
		 .scl			(scl),
		 // Inputs
		 .apb_re		(i2c_apb_re),
		 .apb_we		(i2c_apb_we),
		 .data_in		(i2c_data_in[7:0]),
		 .data_sel		(i2c_data_sel),
		 .data_wr		(i2c_data_wr),
		 .pclk			(pclk),
		 .prst_n		(prst_n));
  
endmodule