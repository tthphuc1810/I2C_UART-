
//------------------------------------------------------------
//-- I2C RECEIVING FIFO
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_rxff(
  //OUTPUT
  rxff_data,
  rxff_rxne,
  rxff_ov,
  //INPUT
  pclk,
  prst_n,
  apb_crx,
  i_rxff_wr,
  rxff_din,
  apb_rxff_rd);
  

//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output [7:0]rxff_data;
output rxff_rxne;
output reg rxff_ov;

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input [7:0] rxff_din;
input   pclk;
input   prst_n;
input   apb_crx;
input   i_rxff_wr;
input   apb_rxff_rd;

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire  fbit_comp;
wire  equal;
wire dt_we_rxfifo, dt_re_rxfifo;
wire overflow_set;
wire rxff_full;
wire rxff_threshold;	
wire apb_crx_up;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [4:0]rxff_wptr,rxff_rptr;
reg [7:0]rxff_memory[15:0];
reg apb_crx1;
reg dt_we_rxfifo1;
reg dt_we_rxfifo2;
reg dt_we_rxfifo3;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign dt_we_rxfifo = (~rxff_full)& i_rxff_wr;
assign dt_re_rxfifo = rxff_rxne & apb_rxff_rd;
assign overflow_set = rxff_full & i_rxff_wr;
assign rxff_data =  rxff_memory[rxff_rptr[3:0]][7:0]; 
assign fbit_comp =  (rxff_wptr[4] ^rxff_rptr[4]);
assign equal = (rxff_wptr[3:0] - rxff_rptr[3:0])? 1'b1 : 1'b0; 
assign rxff_full = fbit_comp & equal;
assign rxff_rxne = (~fbit_comp & equal);
assign apb_crx_up = apb_crx & ~apb_crx1;

//------------------------------------------------------------
//-- MEMMORY ARRAY
//------------------------------------------------------------
always @(posedge pclk) 
begin
	if(dt_we_rxfifo | dt_we_rxfifo) 
        rxff_memory[rxff_wptr[3:0]] <= #`DELAY  rxff_din;
end
 
//------------------------------------------------------------
//-- READ POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
    if(~prst_n) 
        rxff_rptr <= #`DELAY  5'd0;
	else if (apb_crx_up)
		rxff_rptr <= #`DELAY  5'd0;
	else begin
		if(dt_re_rxfifo) 
			rxff_rptr <= #`DELAY  rxff_rptr + 5'd1;
        else 
			rxff_rptr <= #`DELAY  rxff_rptr;
	end
end
    
//------------------------------------------------------------
//-- WRITE POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n) 
		rxff_wptr <= 5'd0;
	else begin
	case ({apb_crx_up , dt_we_rxfifo3})
		2'b00:  rxff_wptr <= #`DELAY  rxff_wptr;
		2'b01:  rxff_wptr <= #`DELAY  rxff_wptr + 5'd1;
		2'b10:  rxff_wptr <= #`DELAY  rxff_rptr;
		2'b11:  rxff_wptr <= #`DELAY  rxff_rptr;          
	endcase
	end
end

//------------------------------------------------------------
//-- OVERFLOW SIGNAL
//------------------------------------------------------------ 
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n)
		rxff_ov <= #`DELAY  1'b0; 
	else begin
	case ({overflow_set , dt_we_rxfifo})
		2'b00:  rxff_ov <= #`DELAY  rxff_ov;
		2'b01:  rxff_ov <= #`DELAY  1'b0;
		2'b10:  rxff_ov <= #`DELAY  1'b1;
		2'b11:  rxff_ov <= #`DELAY  1'b0;          
	endcase
    end
end    

//------------------------------------------------------------
//-- REGISTER SIGNAL 
//------------------------------------------------------------
always @(posedge pclk)
begin
	apb_crx1 <= #`DELAY  apb_crx; 
	dt_we_rxfifo1 <= #`DELAY  dt_we_rxfifo;
	dt_we_rxfifo2 <= #`DELAY  dt_we_rxfifo1;
	dt_we_rxfifo3 <= #`DELAY  dt_we_rxfifo2;
end

endmodule

