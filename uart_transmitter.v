
//------------------------------------------------------------
//-- UART TRANSMITTER
//------------------------------------------------------------

`include "n2v_define.v"

module uart_transmitter(
	// INPUTS
	pclk,	prst_n,		brg_tx_shift,	apb_d9,
	apb_af,	apb_tx_en,	apb_data,		uart_cts,
	// OUTPUTS
	tx_txff_rd,	uart_tx,	tx_busy);
//------------------------------------------------------------
//-- PARAMETER
//------------------------------------------------------------
parameter IDLE = 1'd0,
          TRANSMIT =1'd1;

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input pclk;
input prst_n;
input brg_tx_shift;
input apb_d9;
input apb_af;
input apb_tx_en;
input [7:0] apb_data;
input uart_cts;
  
//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output tx_txff_rd;
output  uart_tx;
output  tx_busy;

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire tx_shift_en;
wire parity;
wire tx_complete;
wire [3:0] bit_shift;
wire uart_cts_mux;
wire fsm_en;
wire fsm_shift_en;
wire [9:0]  init_value;
  
//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [9:0] tx_shift_reg;
reg [3:0] sb_counter;
reg cur_state;
reg next_state;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign tx_shift_en	=	brg_tx_shift & fsm_shift_en;
assign parity		=	^ apb_data[7:0];
assign init_value	=	(apb_d9) ?  {parity,apb_data[7:0],1'b0} : {1'b1,apb_data[7:0],1'b0}; 
assign bit_shift	=	(apb_d9) ? 4'd10 : 4'd9 ;	
assign tx_complete	=	(sb_counter == bit_shift) ;
assign uart_cts_mux	=	(apb_af) ? uart_cts : 1'b0;
assign fsm_en		=	(~uart_cts_mux) & apb_tx_en & brg_tx_shift;
assign tx_txff_rd	=	tx_complete	;
assign uart_tx		=	tx_shift_reg[0];
assign tx_busy		=	cur_state;
assign fsm_shift_en	=	cur_state;

//------------------------------------------------------------
//-- TRANSMITTING SHIFT REGISTER
//------------------------------------------------------------
always @ (posedge pclk,negedge prst_n)
begin
	if(~prst_n)
		tx_shift_reg<=#`DELAY  {10{1'b1}};
	else begin
		casez({fsm_en,tx_shift_en})
		2'b10 :   tx_shift_reg<=#`DELAY init_value;
		2'b?1 :   tx_shift_reg<=#`DELAY {1'b1,tx_shift_reg[9:1]};
		2'b00 :   tx_shift_reg<=#`DELAY tx_shift_reg;
		endcase
	end
end

//------------------------------------------------------------
//-- SHIFT BIT COUNTER
//------------------------------------------------------------
always @ (posedge pclk, negedge prst_n)
	begin
	if(~prst_n)
		sb_counter<=4'b0;
	else
	begin
		casez({tx_complete,tx_shift_en})
		2'b1?:    sb_counter<=#`DELAY 4'b0;
		2'b01:    sb_counter<=#`DELAY sb_counter+4'b1;
		2'b00:    sb_counter<=#`DELAY sb_counter;
		endcase
	end		
end

//------------------------------------------------------------
//-- FINITE STATE MACHINE
//------------------------------------------------------------
always @ (posedge pclk, negedge prst_n)
begin
	if(~prst_n)
		cur_state<=#`DELAY IDLE;
	else
		cur_state<=#`DELAY next_state;
end
		
always @(*)
begin
	casez(cur_state)
	IDLE : begin
		if(~apb_tx_en)
			next_state	= IDLE;
		else if (fsm_en)
			next_state	= TRANSMIT;
		else  
			next_state	= IDLE;
	end
	TRANSMIT: begin
		if((~apb_tx_en)|tx_complete)
			next_state	= IDLE;
		else  
			next_state	= TRANSMIT;
	end
	endcase
end

endmodule



     
