
//------------------------------------------------------------
//-- I2C CLOCK GENERATOR
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_clock(
	// Inputs
	apb_csel, pclk, prst_n, i_clock_en, i_clock_stop,
	// Outputs
	i_clk
	);

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input [1:0]apb_csel;
input pclk;
input prst_n;
input i_clock_en;
input i_clock_stop;

//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
  output i_clk; 

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire ice_down;
wire ics_down;
wire ice_enable;
wire ics_enable;
wire clear;
wire pre_iclk;
wire [8:0]clock_rate;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [1:0] ice_counter;
reg [1:0] ics_counter;
reg [8:0]clock_counter;
reg i_clock_en_pre;
reg i_clock_stop_longer_edge_pre;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------

//------BAT SUON XUONG CLOCK EN & CLOCK STOP-----
assign ice_down = i_clock_en_pre & (~i_clock_en);
assign ics_down = i_clock_stop_longer_edge_pre & (~i_clock_stop);

//------GIU TIN HIEU ENABLE VA STOP CLOCK--------
assign ice_enable = (ice_counter > 0); 
assign ics_enable = (ics_counter > 0);

assign clock_rate = apb_csel[1] ? (apb_csel[0] ? 15 : 125) : (apb_csel[0] ? 50 : 500);
assign pre_iclk = (clock_counter >= clock_rate/2);
assign clear = (clock_counter == clock_rate);
assign i_clk = (ics_enable | ~ice_enable | i_clock_en)?1'b1:pre_iclk;

always @(posedge pclk,negedge prst_n) 
begin
	if(~prst_n) 
	begin 
		i_clock_en_pre <= #`DELAY 1'b0;
		i_clock_stop_longer_edge_pre <= #`DELAY 1'b0;
	end
    else 
	begin 
        i_clock_en_pre <= #`DELAY i_clock_en;
        i_clock_stop_longer_edge_pre <= #`DELAY i_clock_stop;
	end
end
  

always @(posedge pclk, negedge prst_n)
begin
	if(~prst_n) ice_counter <= #`DELAY 2'b0;
	else 
	begin
	casex({ice_down, ics_down})
		2'b01: ice_counter <= #`DELAY 2'b00;
		2'b11: ice_counter <= #`DELAY 2'b00;
		2'b10: ice_counter <= #`DELAY ice_counter + 1'd1;
		2'b00: ice_counter <= #`DELAY ice_counter;
		default: ice_counter <= #`DELAY ice_counter;
	endcase
	end
end
  

always @(posedge pclk, negedge prst_n)
begin
	if(~prst_n) ics_counter <= #`DELAY 2'b0;
	else 
	begin
	case({ics_down, ice_down})
		2'b01: ics_counter <= #`DELAY 2'b00;
		2'b11: ics_counter <= #`DELAY 2'b00;
		2'b10: ics_counter <= #`DELAY ics_counter + 1'd1;
		2'b00: ics_counter <= #`DELAY ics_counter;
	default: ics_counter <= #`DELAY ics_counter;
	endcase
	end
end
  
//-----------------------------------------------
//------------------TAO I_CLK--------------------
//-----------------------------------------------
always @(posedge pclk, negedge prst_n)
begin
	if (~prst_n) clock_counter <= #`DELAY 9'd0;
	else
	begin
		if ((~ice_enable)) 
			clock_counter <= #`DELAY 9'd0;
		else 
			clock_counter <= #`DELAY clock_counter + 9'd1; 
	end 
end
    


endmodule
