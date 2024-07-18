
//------------------------------------------------------------
//-- I2C TRANSMITTING FIFO
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_txff(
  //OUTPUT
  txff_data,
  txff_txnf,
  txff_empty,
//  txff_ov,
  //INPUT
  pclk,
  prst_n,
  apb_ctx,
  i_txff_rd,
  apb_data,
  apb_txff_wr);
  

//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output [7:0]txff_data;
output txff_txnf;
output txff_empty;
//output reg rxff_ov;

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input [7:0] apb_data;
input pclk;
input prst_n;
input apb_ctx;
input i_txff_rd;
input apb_txff_wr;

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire fbit_comp;
wire equal;
wire dt_we_txfifo, dt_re_txfifo;
wire overflow_set;
wire txff_full;
wire txff_txne ;  
wire apb_ctx_up;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [4:0]txff_wptr,txff_rptr;
reg [7:0]txff_memory[15:0];
reg txff_ov;
reg apb_ctx1;
reg dt_we_txfifo1;
reg dt_we_txfifo2;
reg dt_we_txfifo3;

reg dt_re_txfifo1;
reg dt_re_txfifo2;
reg dt_re_txfifo3;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign apb_ctx_up = apb_ctx & ~apb_ctx1;
assign fbit_comp 	=  (txff_wptr[4] ^txff_rptr[4]);
assign equal 		= (txff_wptr[3:0] == txff_rptr[3:0]);
assign txff_full 	= fbit_comp & equal;
assign txff_txne 	= ~(~fbit_comp & equal);
assign txff_empty 	= ~fbit_comp & equal;
assign dt_we_txfifo = (~txff_full)& apb_txff_wr;
assign dt_re_txfifo = txff_txne & i_txff_rd;
assign overflow_set = txff_full & dt_we_txfifo;
assign txff_txnf = ~txff_full;
assign txff_data =  txff_memory[txff_rptr[3:0]];

//------------------------------------------------------------
//-- MEMMORY ARRAY
//------------------------------------------------------------
always @(posedge pclk) 
begin
	if(dt_we_txfifo|dt_we_txfifo1) 
	txff_memory[txff_wptr[3:0]] <= #`DELAY  apb_data;
end
 
//------------------------------------------------------------
//-- READ POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n) 
		txff_rptr <= #`DELAY  5'd0;
	else if (apb_ctx_up)
		txff_rptr <= #`DELAY  5'd0;
	else begin
		if(dt_re_txfifo3) 
			txff_rptr <= #`DELAY  txff_rptr + 5'd1;
        else 
			txff_rptr <= #`DELAY  txff_rptr;
	end
end
    
//------------------------------------------------------------
//-- WRITE POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n) 
		txff_wptr <= #`DELAY 5'd0;
	else begin
	case ({apb_ctx_up,dt_we_txfifo3})
		2'b00:  txff_wptr <= #`DELAY  txff_wptr;
		2'b01:  txff_wptr <= #`DELAY  txff_wptr + 5'd1;
		2'b10:  txff_wptr <= #`DELAY  txff_rptr;
		2'b11:  txff_wptr <= #`DELAY  txff_rptr;          
	endcase
	end
end

	
//------------------------------------------------------------
//-- OVERFLOW SIGNAL
//------------------------------------------------------------  
always @(posedge pclk or negedge prst_n) 
begin
    if(~prst_n)
		txff_ov <= #`DELAY  1'b0; 
    else begin
	case ({overflow_set , dt_re_txfifo})
		2'b00:  txff_ov <= #`DELAY  txff_ov;
		2'b01:  txff_ov <= #`DELAY  1'b0;
		2'b10:  txff_ov <= #`DELAY  1'b1;
		2'b11:  txff_ov <= #`DELAY  1'b0;          
	endcase
    end
end    


always @(posedge pclk, negedge prst_n)
begin
	if(~prst_n) begin
	apb_ctx1 <= #`DELAY  1'b0;
	dt_we_txfifo1 <= #`DELAY  1'b0;
	dt_we_txfifo2 <= #`DELAY  1'b0;
	dt_we_txfifo3 <= #`DELAY  1'b0;
	dt_re_txfifo1 <= #`DELAY  1'b0;
	dt_re_txfifo2 <= #`DELAY  1'b0;
	dt_re_txfifo3 <= #`DELAY  1'b0;
	end 
	else begin	
	apb_ctx1 <= #`DELAY  apb_ctx;
	dt_we_txfifo1 <= #`DELAY  dt_we_txfifo;
	dt_we_txfifo2 <= #`DELAY  dt_we_txfifo1;
	dt_we_txfifo3 <= #`DELAY  dt_we_txfifo2;
	dt_re_txfifo1 <= #`DELAY  dt_re_txfifo;
	dt_re_txfifo2 <= #`DELAY  dt_re_txfifo1;
	dt_re_txfifo3 <= #`DELAY  dt_re_txfifo2;
	end
end
endmodule
