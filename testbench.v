`include	"n2v_define.v"
module	tb_iuf;
parameter CYCLE = 10;
/*AUTOREGINPUT*/
// Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
reg			apb_re;			// To nmf of i2c_uart_fpga.v
reg			apb_we;			// To nmf of i2c_uart_fpga.v
reg [7:0]		data_in;		// To nmf of i2c_uart_fpga.v
reg			data_sel;		// To nmf of i2c_uart_fpga.v
reg			data_wr;		// To nmf of i2c_uart_fpga.v
reg			i2c_apb_re;		// To nmf of i2c_uart_fpga.v
reg			i2c_apb_we;		// To nmf of i2c_uart_fpga.v
reg [7:0]		i2c_data_in;		// To nmf of i2c_uart_fpga.v
reg			i2c_data_sel;		// To nmf of i2c_uart_fpga.v
reg			i2c_data_wr;		// To nmf of i2c_uart_fpga.v
reg			pclk;			// To nmf of i2c_uart_fpga.v
reg			prst_n;			// To nmf of i2c_uart_fpga.v
reg			uart_cts;		// To nmf of i2c_uart_fpga.v
reg			uart_rx;		// To nmf of i2c_uart_fpga.v
// End of automatics
/*AUTOWIRE*/
// Beginning of automatic wires (for undeclared instantiated-module outputs)
wire [7:0]		i2c_data_out;		// From nmf of i2c_uart_fpga.v
wire			i2c_i2c_if;		// From nmf of i2c_uart_fpga.v
wire			i2c_if;			// From nmf of i2c_uart_fpga.v
wire			rx_rts;			// From nmf of i2c_uart_fpga.v
`ifdef  UART_COMBINE_INTERRUPT
wire			uart_if;		// From nmf of i2c_uart_fpga.v
`else
wire			uart_fif;		// From nmf of i2c_uart_fpga.v
wire			uart_oif;		// From nmf of i2c_uart_fpga.v
wire			uart_pif;		// From nmf of i2c_uart_fpga.v
wire			uart_rif;		// From nmf of i2c_uart_fpga.v
`endif
wire			uart_tif;		// From nmf of i2c_uart_fpga.v
wire			uart_tx;		// From nmf of i2c_uart_fpga.v
// End of automatics
integer s,m;

i2c_uart_fpga iuf(/*AUTOINST*/
		    // Outputs
		    .i2c_data_out	(i2c_data_out[7:0]),
		    .i2c_i2c_if		(i2c_i2c_if),
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
		    // Inputs
		    .apb_re		(apb_re),
		    .apb_we		(apb_we),
		    .data_in		(data_in[7:0]),
		    .data_sel		(data_sel),
		    .data_wr		(data_wr),
		    .i2c_apb_re		(i2c_apb_re),
		    .i2c_apb_we		(i2c_apb_we),
		    .i2c_data_in	(i2c_data_in[7:0]),
		    .i2c_data_sel	(i2c_data_sel),
		    .i2c_data_wr	(i2c_data_wr),
		    .pclk		(pclk),
		    .prst_n		(prst_n),
		    .uart_cts		(uart_cts),
		    .uart_rx		(uart_tx));
// 8. Initial Conditions
initial
	begin
		apb_re = 1'b0 ;			
		apb_we = 1'b0;			
		data_wr = 1'b0;		
		i2c_apb_re = 1'b0;
		i2c_apb_we = 1'b0;
		i2c_data_wr = 1'b0;
		pclk = 1'b0;
		prst_n = 1'b0;
		uart_cts = 1'b0;
	end
// 9. Generating Test Vectors
initial
	begin
		main;
	end
task main;
	fork
		clock_gen;
		reset_gen;
		operation_flow;
	join
endtask
task clock_gen;
	begin
		forever #CYCLE pclk = !pclk;
	end
endtask

task reset_gen;
	begin
		prst_n = 1'b0;
		#(CYCLE*2)
		prst_n = 1'b1;
		/*
		#(CYCLE*20000)
		prst_n = 1'b0;
		#(CYCLE*200)
		prst_n = 1'b1;
		*/
	end
endtask

task operation_flow;
	begin

//-------------------------------------
//-------I2C SLAVE CONFIGURATION-------
//-------------------------------------

		
// I2C SLAVE CONTROL
    #(CYCLE*22)
		i2c_data_in 	= 8'h1C;	
		i2c_data_sel 	= 1'b0;
		#(CYCLE*6)
		i2c_data_wr	= 1'b1;		
		#(CYCLE*6) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*11)
		i2c_data_in 	= 3'b011;
		i2c_data_sel  = 1'b1;
		#(CYCLE*6) 
		i2c_data_wr	= 1'b1;		
		#(CYCLE*11) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*30) 
		i2c_apb_we	= 1'b1;		
		#(CYCLE*11) 
		i2c_apb_we	= 1'b0;


// I2C SLAVE STATUS
    #(CYCLE*22)
		i2c_data_in 	= 8'h20;
		i2c_data_sel 	= 1'b0;
		#(CYCLE*6)
		i2c_data_wr	= 1'b1;		
		#(CYCLE*6) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*11)
		i2c_data_in 	= 1'b1;
		i2c_data_sel  = 1'b1;
		#(CYCLE*6) 
		i2c_data_wr	= 1'b1;		
		#(CYCLE*11) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*30) 
		i2c_apb_we	= 1'b1;		
		#(CYCLE*11) 
		i2c_apb_we	= 1'b0;

		
// I2C SLAVE ADDRESS
    #(CYCLE*22)
		i2c_data_in 	= 8'h24;
		i2c_data_sel 	= 1'b0;
		#(CYCLE*6)
		i2c_data_wr	= 1'b1;		
		#(CYCLE*6) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*11)
		i2c_data_in 	= 7'b1010101;
		i2c_data_sel  = 1'b1;
		#(CYCLE*6) 
		i2c_data_wr	= 1'b1;		
		#(CYCLE*11) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*30) 
		i2c_apb_we	= 1'b1;		
		#(CYCLE*11) 
		i2c_apb_we	= 1'b0;
		
// I2C SLAVE INTERRUPT ENABLE
    #(CYCLE*22)
		i2c_data_in 	= 8'h30;
		i2c_data_sel 	= 1'b0;
		#(CYCLE*6)
		i2c_data_wr	= 1'b1;		
		#(CYCLE*6) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*11)
		i2c_data_in 	= 3'b111;
		i2c_data_sel  = 1'b1;
		#(CYCLE*6) 
		i2c_data_wr	= 1'b1;		
		#(CYCLE*11) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*30) 
		i2c_apb_we	= 1'b1;		
		#(CYCLE*11) 
		i2c_apb_we	= 1'b0;


// I2C SLAVE DATA
  for (s = 0;s < 5; s = s + 1 )
   begin
    #(CYCLE*22)
		i2c_data_in 	= 8'h2C;
		i2c_data_sel 	= 1'b0;
		#(CYCLE*6)
		i2c_data_wr	= 1'b1;		
		#(CYCLE*6) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*11)
		i2c_data_in 	= s+127;
		i2c_data_sel  = 1'b1;
		#(CYCLE*6) 
		i2c_data_wr	= 1'b1;		
		#(CYCLE*11) 
		i2c_data_wr	= 1'b0;
		#(CYCLE*30) 
		i2c_apb_we	= 1'b1;		
		#(CYCLE*11) 
		i2c_apb_we	= 1'b0;
	end
	
//-------------------------------------
//---------UART CONFIGURATION----------
//-------------------------------------
// UART CONTROL
    #(CYCLE*22)
		data_in 	= 8'h00;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 7'b1110101;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
		
// UART BAUDRATE
    #(CYCLE*22)
		data_in 	= 8'h08;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 8'b00011001; //25 -> 128000
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
		
// UART INTERRUPT ENABLE
    #(CYCLE*22)
		data_in 	= 8'h10;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 5'b11111;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;

// UART STATUS
    #(CYCLE*22)
		data_in 	= 8'h04;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b011;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;


//------------------------------------
//-----I2C MASTER CONFIGURATION-------
//------------------------------------

// I2C MASTER STATUS
    #(CYCLE*22)
		data_in 	= 8'h20;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 1'b1;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;

// I2C MASTER CONTROL
    #(CYCLE*22)
		data_in 	= 8'h1C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b111;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
		
/*// I2C MASTER ADDRESS
    #(CYCLE*22)
		data_in 	= 8'h24;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 7'b1010101;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
	*/
			
// I2C MASTER TRANSMIT ADDRESS
    #(CYCLE*22)
		data_in 	= 8'h40;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 7'b1010101;	//85
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
	
// I2C MASTER INTERRUPT ENABLE
    #(CYCLE*22)
		data_in 	= 8'h30;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b111;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;

// I2C MASTER CLOCK DIVIDER
    #(CYCLE*22)
		data_in 	= 8'h3C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 2'b00;	
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;

		
// I2C MASTER COMMAND
    #(CYCLE*400)
		data_in 	= 8'h28;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b011;	// start / master READ
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
		

// I2C MASTER DATA
  for (m = 0;m < 5; m = m+ 1 )
   begin
    #(CYCLE*22)
		data_in 	= 8'h2C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= m+1;
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
	end
	
// I2C MASTER COMMAND
    #(CYCLE*44000)
		data_in 	= 8'h28;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b110;	// start / master write
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;
			

// I2C MASTER COMMAND
    #(CYCLE*40000)
		data_in 	= 8'h28;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
		data_in 	= 3'b001;	// stop / master read
		data_sel  = 1'b1;
		#(CYCLE*6) 
		data_wr	= 1'b1;		
		#(CYCLE*11) 
		data_wr	= 1'b0;
		#(CYCLE*30) 
		apb_we	= 1'b1;		
		#(CYCLE*11) 
		apb_we	= 1'b0;

//------------------------------------
//--------------------------------
//------------------------------------	

// READ I2C
    #(CYCLE*1000)
		data_in 	= 8'h2C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;
	  
	  #(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;
	  
	  #(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;
	  
//WRITE UART
    #(CYCLE*100)
		data_in 	= 8'h0C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
	  apb_we = 1'b1;
	  #(CYCLE*11)
	  apb_we = 1'b0;
	  
	  #(CYCLE*11)
	  apb_we = 1'b1;
	  #(CYCLE*11)
	  apb_we = 1'b0;
	  
	  #(CYCLE*11)
	  apb_we = 1'b1;
	  #(CYCLE*11)
	  apb_we = 1'b0; 
	  
//READ UART
    #(CYCLE*8000)
		data_in 	= 8'h0C;
		data_sel 	= 1'b0;
		#(CYCLE*6)
		data_wr	= 1'b1;		
		#(CYCLE*6) 
		data_wr	= 1'b0;
		#(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;
	  
	  #(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;
	  
	  #(CYCLE*11)
	  apb_re = 1'b1;
	  #(CYCLE*11)
	  apb_re = 1'b0;

	end
endtask
  
endmodule
