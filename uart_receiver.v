
//------------------------------------------------------------
//-- UART RECEIVER
//------------------------------------------------------------

`include "n2v_define.v"

module uart_receiver(
  //OUTPUT
  rx_data,	rx_rts,	rx_busy,	rx_rxne,	rx_ov,	rx_pe,	rx_fe,	rx_rxf,
  //INPUT
  pclk		,  prst_n	,  apb_bsel		,  apb_rxt		,  apb_d9,	apb_en,  
  apb_crx	,  apb_af	,  apb_rxff_rd	,  brg_rx_shift	,  uart_rx
  );

//------------------------------------------------------------
//-- PARAMETER
//------------------------------------------------------------
parameter	IDLE		= 2'b00;
parameter	START_BIT	= 2'b01;
parameter	RECEIVE		= 2'b10;

//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output	rx_rts;
output 	rx_rxne;
output 	rx_fe;
output 	rx_pe;
output 	rx_ov;
output 	rx_rxf;
output 	[7:0]rx_data;
output  rx_busy;

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input	[1:0] apb_rxt;
input   pclk;
input	prst_n;
input	apb_bsel;
input	apb_d9;
input	apb_en;
input	apb_crx;
input	apb_af;
input	apb_rxff_rd;
input	brg_rx_shift;
input	uart_rx;

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire	counter_en;
wire	set_samp_counter;
wire	samp_point;
wire	rx_shift_en;
wire	set_rx_bitcnt;
wire	clr_rx_bitcnt;
wire	rx_complete;
wire	start_en;
wire	pe;
wire	fe;
wire	fbit_comp;
wire	equal;
wire	rx_threshold;
wire 	[9:0]fifo_in;
wire	[9:0] rxfifo_out;
wire 	dt_we_rxfifo;
wire	dt_re_rxfifo;
wire 	overflow_set;
wire	clr_samp_counter;
wire	fsm_start_bit;
wire	fsm_receive ;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [4:0]rx_wptr,rx_rptr;
reg dt_we_rxfifo1;
reg dt_we_rxfifo2;
reg dt_we_rxfifo3;
reg [9:0]rx_memory[15:0];
reg rx_ov;  
reg [1:0] cur_state,next_state;
reg [3:0]samp_counter;
reg [3:0]rx_bitcounter;
reg [9:0]rx_shift_reg;
reg uart_rx1;
reg	uart_rx_sync;
reg	uart_rx2;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign counter_en 		= fsm_receive | fsm_start_bit;
assign set_samp_counter = counter_en & brg_rx_shift;
assign samp_point 		= ~apb_bsel ? (samp_counter == 7):(samp_counter[2:0] == 3);
assign rx_shift_en 		= samp_point & brg_rx_shift;
assign set_rx_bitcnt 	= fsm_receive & rx_shift_en;
assign clr_rx_bitcnt 	= rx_complete;
assign rx_complete 		= rx_bitcounter == (apb_d9 ? 10:9);
assign start_en 		= ~uart_rx_sync & uart_rx2;
// RXFF
assign dt_we_rxfifo 	= ~rx_rxf &rx_complete;
assign dt_re_rxfifo 	= rx_rxne & apb_rxff_rd;
assign rx_threshold 	= (rx_wptr - rx_rptr) >=  (apb_rxt[1] ? (apb_rxt[0] ? 16 : 8) : (apb_rxt[0] ? 4 : 2));
assign overflow_set 	= rx_rxf & dt_we_rxfifo; 
//CO PARITY, FRAME
assign pe				= ^rx_shift_reg[8:0]; // even parity 
assign fe 				= !rx_shift_reg[9];   // stop bit checking
//DATA IN FOR RXFIFO
assign fifo_in 			= apb_d9 ? {rx_shift_reg[7:0] , pe , fe} :{rx_shift_reg[8:1] , 1'b0 , fe};
assign rx_rts 			= (rx_threshold & apb_af);
//OUTPUT OF FSM
assign rx_busy 			= |cur_state;
assign fsm_receive 		= cur_state[1];
assign fsm_start_bit 	= cur_state[0];
assign clr_samp_counter = ~rx_busy;  
// 
assign rxfifo_out		= rx_memory[rx_rptr[3:0]];
assign rx_pe 			= rx_rxne & rxfifo_out[1]; 
assign rx_fe 			= rx_rxne & rxfifo_out[0];
assign rx_data 			=  rxfifo_out[9:2];
assign fbit_comp 		=  (rx_wptr[4] ^ rx_rptr[4]);
assign equal 			= (rx_wptr[3:0] == rx_rptr[3:0]);
//FULL
assign rx_rxf 			= fbit_comp & equal;
//EMPTY
assign rx_rxne 			= ~(~fbit_comp & equal);


//------------------------------------------------------------
//-- FINITE STATE MACHINE
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n ) 
		cur_state <=  #`DELAY IDLE;
	else if(~apb_en)
		cur_state <= #`DELAY IDLE;
	else
		cur_state <= #`DELAY  next_state;
end

always @(*)
begin
	case (cur_state)
	IDLE:
		if(start_en)	next_state = START_BIT;
		else			next_state = cur_state;
	
	START_BIT: 
		if (uart_rx_sync)		next_state = IDLE;
		else if(rx_shift_en)	next_state = RECEIVE;
		else					next_state = cur_state;

	RECEIVE: 
		if(rx_complete)		next_state = IDLE;
		else				next_state = cur_state;

	default:
		next_state = cur_state;
    endcase
end

//------------------------------------------------------------
//-- SAMP_COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n )
begin
	if (~prst_n)    
		samp_counter <= #`DELAY  4'b0;
	else begin
	case ({set_samp_counter,clr_samp_counter})
		2'b00: samp_counter <= #`DELAY  samp_counter;
		2'b01: samp_counter <= #`DELAY  4'b0;
		2'b10: samp_counter <= #`DELAY  samp_counter + 4'd1;
		2'b11: samp_counter <= #`DELAY  4'b0;
		default: samp_counter <= #`DELAY  samp_counter;
	endcase
    end
end

//------------------------------------------------------------
//-- RX_BITCOUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n )
begin
	if (~prst_n)    
		rx_bitcounter <= #`DELAY  1'b0;
    else 
    case({set_rx_bitcnt, clr_rx_bitcnt})
		2'b00: rx_bitcounter <= #`DELAY  rx_bitcounter;
		2'b01: rx_bitcounter <= #`DELAY  1'b0;
		2'b10: rx_bitcounter <= #`DELAY  rx_bitcounter + 1'b1;
		2'b11: rx_bitcounter <= #`DELAY  1'b0;
		default: rx_bitcounter <= #`DELAY  rx_bitcounter;
    endcase
end

//------------------------------------------------------------
//-- UART_RECEIVER SYNC
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n) begin
	uart_rx1 <= #`DELAY  1'b0;
	uart_rx_sync <= #`DELAY  1'b0;
	uart_rx2 <= #`DELAY  1'b0;
	dt_we_rxfifo1<= #`DELAY 1'b0;
	dt_we_rxfifo2<= #`DELAY 1'b0;
	dt_we_rxfifo3<= #`DELAY 1'b0;
	end
	else begin
	uart_rx1 <= #`DELAY  uart_rx;
	uart_rx_sync <= #`DELAY  uart_rx1;
	uart_rx2 <= #`DELAY  uart_rx_sync;
	dt_we_rxfifo1<= #`DELAY dt_we_rxfifo;
	dt_we_rxfifo2<= #`DELAY dt_we_rxfifo1;
	dt_we_rxfifo3<= #`DELAY dt_we_rxfifo2;
	end
end

//------------------------------------------------------------
//-- RECEIVING SHIFT REGISTER
//------------------------------------------------------------
always @(posedge pclk)
begin
    if (rx_shift_en)
		rx_shift_reg <= #`DELAY   {uart_rx_sync, rx_shift_reg[9:1]} ;
end

//------------------------------------------------------------
//-- READ POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n) 
		rx_rptr <= #`DELAY  5'd0;
	else begin
        if(dt_re_rxfifo) 
			rx_rptr <= #`DELAY  rx_rptr + 5'd1;
        else 
			rx_rptr <= #`DELAY  rx_rptr;
	end
end

//------------------------------------------------------------
//-- WRITE POINTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n) 
begin
	if(~prst_n) 
		rx_wptr <= #`DELAY 5'd0;
	else begin
	case ({apb_crx,dt_we_rxfifo3})
		2'b00:  rx_wptr <= #`DELAY  rx_wptr;
		2'b01:  rx_wptr <= #`DELAY  rx_wptr + 5'd1;
		2'b10:  rx_wptr <= #`DELAY  rx_rptr;
		2'b11:  rx_wptr <= #`DELAY  rx_rptr;          
	endcase
	end
end

//------------------------------------------------------------
//-- MEMMORY ARRAY
//------------------------------------------------------------
always @(posedge pclk)
begin
	if(dt_we_rxfifo | dt_we_rxfifo1)
		rx_memory[rx_wptr[3:0]] <= #`DELAY fifo_in;
end
  
//------------------------------------------------------------
//-- OVERFLOW CONTROL
//------------------------------------------------------------
always @(posedge pclk) 
begin
    if(~prst_n)
		rx_ov <= #`DELAY  1'b0; 
    else begin
	case ({overflow_set , dt_re_rxfifo})
		2'b00:  rx_ov <= #`DELAY  rx_ov;
		2'b01:  rx_ov <= #`DELAY  1'b0;
		2'b10:  rx_ov <= #`DELAY  1'b1;
		2'b11:  rx_ov <= #`DELAY  1'b0;          
	endcase
    end
end    

endmodule

