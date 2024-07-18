
//------------------------------------------------------------
//-- I2C FPGA
//------------------------------------------------------------

`include "n2v_define.v"

module i2c_fpga (/*AUTOARG*/
   // Outputs
   i2c_i2c_if, i2c_data_out,
   // Inouts
   sda, scl,
   // Inputs
   prst_n, pclk, i2c_data_wr, i2c_data_sel, i2c_data_in, i2c_apb_we, i2c_apb_re
   );

/*AUTOINPUT*/
// Beginning of automatic inputs (from unused autoinst inputs)
input			i2c_apb_re;			// To apbmaster of apb_master.v
input			i2c_apb_we;			// To apbmaster of apb_master.v
input [7:0]		i2c_data_in;		// To apbmaster of apb_master.v
input			i2c_data_sel;		// To apbmaster of apb_master.v
input			i2c_data_wr;		// To apbmaster of apb_master.v
input			pclk;			// To icore of i2c_core.v, ...
input			prst_n;			// To icore of i2c_core.v, ...
// End of automatics

/*AUTOOUTPUT*/
// Beginning of automatic outputs (from unused autoinst outputs)
output [7:0]		i2c_data_out;		// From apbmaster of apb_master.v
output			i2c_i2c_if;			// From icore of i2c_core.v
// End of automatics

inout sda, scl;

/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire [31:0]		paddr;			// From apbmaster of apb_master.v
wire			penable;		// From apbmaster of apb_master.v
wire [31:0]		prdata;			// From icore of i2c_core.v
wire			psel;			// From apbmaster of apb_master.v
wire [31:0]		pwdata;			// From apbmaster of apb_master.v
wire			pwrite;			// From apbmaster of apb_master.v
// End of automatics

i2c_core 	i2c_s(/*AUTOINST*/
		      // Outputs
		      .i2c_if		(i2c_i2c_if),
		      .prdata		(prdata[31:0]),
		      // Inouts
		      .sda		(sda),
		      .scl		(scl),
		      // Inputs
		      .paddr		(paddr[7:0]),
		      .pclk		(pclk),
		      .penable		(penable),
		      .prst_n		(prst_n),
		      .psel		(psel),
		      .pwdata		(pwdata[31:0]),
		      .pwrite		(pwrite));

apb_master_1		apb_s(/*AUTOINST*/
				  // Outputs
				  .pwrite		(pwrite),
				  .penable		(penable),
				  .psel			(psel),
				  .paddr		(paddr[31:0]),
				  .pwdata		(pwdata[31:0]),
				  .data_out		(i2c_data_out[7:0]),
				  // Inputs
				  .pclk			(pclk),
				  .prst_n		(prst_n),
				  .data_sel		(i2c_data_sel),
				  .data_wr		(i2c_data_wr),
				  .data_in		(i2c_data_in[7:0]),
				  .apb_we		(i2c_apb_we),
				  .apb_re		(i2c_apb_re),
				  .prdata		(prdata[31:0]));


endmodule  
  
