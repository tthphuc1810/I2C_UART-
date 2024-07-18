
//------------------------------------------------------------
//-- I2C INTERFACE
//------------------------------------------------------------

`include "n2v_define.v"

module i2c_interface(	
	// Inputs
	pclk, prst_n, i_clk, txff_data, apb_en, apb_ms, apb_sp, 
	apb_rs, apb_rw,	apb_add, apb_tadd, apb_csel, rxff_ov,txff_empty,
	// Outputs						
	i_rx_busy, i_tx_busy, i_txff_rd, i_rxff_wr, rxff_din, 
	i_clock_en, i_clock_stop, i_mrs, scl, sda
	);

//------------------------------------------------------------
//-- PARAMETER
//------------------------------------------------------------
parameter 	
    M_IDLE 		   = 3'b000,
	M_FIRSTBYTE = 3'b001,
	M_RECEIVE   = 3'b010,
	M_TRANSMIT 	= 3'b011,
	S_IDLE 		   = 3'b100,
	S_FIRSTBYTE = 3'b101,
	S_RECEIVE 	 = 3'b110,
	S_TRANSMIT 	= 3'b111;

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input pclk;				// Clock signal from APB bus
input prst_n;			// Reset signal from APB bus
input i_clk;			// Clock signal of I2C clock generator
input [7:0]txff_data;	// Read data from Transmitting FIFO
input apb_en;			// I2C Enable signal 
input apb_ms;			// I2C master/slaver signal
input apb_sp;			// I2C start/stop signal
input apb_rs;			// I2C restart signal
input apb_rw;			// I2C read/write signal
input [1:0]apb_csel;			// Clock select signal
input [6:0]apb_add;		// Address of I2C module
input [6:0]apb_tadd;	// Address of I2C slaver being communicated
input rxff_ov;
input txff_empty;

//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output i_rx_busy;		// Busy in receiving mode
output i_tx_busy;		// Busy in transmitting operation
output i_txff_rd;		// Read signal to transmitting FIFO
output i_rxff_wr;		// Writing signal to receiving FIFO
output [7:0]rxff_din;	// Writing data to receiving FIFO
output i_clock_en;		// Enable signal to Clock Generator
output i_mrs;			// Restart signal to Clock Generator
output i_clock_stop;	// Disable signal to Clock Generator

//------------------------------------------------------------
//-- INOUT SIGNAL
//------------------------------------------------------------
inout sda;				// Serial data line
inout scl;				// Serial clock line

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire scl_up;			// Rising clock edge
wire scl_down;			// Falling clock edge
wire sda_down;			// Rising data edge
wire sda_up;			// Falling data edge
wire bc_down_complete;	// Falling clock edge counter completed signal
wire bc_up_complete;	// Rising clock edge counter completed signal
wire bcd0;				// Falling clock edge counter = 0
wire bcd9;				// Falling clock edge counter = 9
wire bcu0;				// Rising clock edge counter = 0
wire bcu9;				// Rising clock edge counter = 9
wire [31:0] one_cycle;	// One SCL cycle
wire [31:0] two_cycle;	// Two SCL cycle

wire apb_ms_up;			// Rising edge of 'master/slaver' signal
wire apb_ms_down;		// Falling edge of 'master/slaver' signal

wire s_fsm_idle;		// SLAVER IDLE state
wire s_fsm_firstbyte;	// SLAVER FIRSTBYTE state
wire s_fsm_receive;		// SLAVER RECEIVE state
wire s_fsm_transmit;	// SLAVER TRANSMIT state
reg [7:0] s_init_value;// Shift data for transmitting slaver
wire s_tx_shift_en;		// Shifting enable signal in transmitting mode of slaver
wire s_rx_shift_en;		// Shifting enable signal in receiving mode of slaver
wire s_r;				// Changing to SLAVER RECEIVE state
wire s_w;				// Changing to SLAVER TRANSMIT state
wire s_right_addr;		// Checking the address transmitted by the master
wire s_rx_busy;			// Busy signal for SLAVER RECEIVE state
wire s_tx_busy;			// Busy signal for SLAVER TRANSMIT state
wire s_start;			// Start condition detecting signal for the slaver
wire s_stop;			// Stop condition detecting signal for the slaver
wire s_ack_ok;			// Checking returned-ACK by the master in SLAVER TRANSMIT state
wire start_complete;	// Completing signal for start counter of MASTER
wire ack_return;		// Interval for returning ACK bit of SLAVER
wire s_stop_detect;		// Stop detecting signal for SLAVER
wire s_rs_detect;		// Restart detecting signal for SLAVER


//wire m_fsm_idle;		// MASTER IDLE state
wire m_fsm_firstbyte;	// MASTER FIRSTBYTE state
wire m_fsm_receive;		// MASTER RECEIVE state
wire m_fsm_transmit;	// MASTER TRANSMIT state
wire [7:0] m_init_value;// Shift data for transmitting master
wire m_tx_shift_en;		// Shifting enable signal in transmitting mode of master
wire m_rx_shift_en;		// Shifting enable signal in receiving mode of master
wire m_r;				// Changing to MASTER RECEIVE state
wire m_w;				// Changing to MASTER TRANSMIT state
wire m_rx_busy;			// Busy signal for MASTER RECEIVE state
wire m_tx_busy;			// Busy signal for MASTER TRANSMIT state
wire m_ack_ok;			// Checking returned-ACK by the slaver
wire m_rs_interval;		// Interval for generating restart condition
wire m_restart;			// Restart signal 
wire rs_clr;			// Signal for clearing 'reset counter'
wire mrs_one;			// Interval of one scl cycle for restarting 
wire mrs_one_down;		// Falling edge of 'mrs_one'
wire mrs_three_down;		// Falling edge of 'mrs_one'
wire mrs_two;			// Interval of two scl cycle for restarting 
wire mrs_three;			// Interval of three scl cycle for restarting 
wire m_stop;			// Stop interval generated by TRANSMITTING MASTER 
wire m_stop_up;			// Rising edge of 'm_stop' - stop condition
wire ics_en;			// STOP combined condition generated by MASTER 
wire ics_clr;			// Clearing 'stop counter' signal

wire hiz;				// High impedance condition of SDA
wire m_hiz;				// Master high impedance condition of SDA
wire s_hiz;				// Slaver high impedance condition of SDA
wire zero;				// '1'b0' condition of SDA
wire one;				// '1'b1' condition of SDA

wire ics_one;
wire ics_two;
wire ics_three;
wire sda;				// Serial data line

wire [31:0] clock_rate;
wire s_firstbyte_to_idle;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [3:0]bc_down;		// Falling SCL edge counter
reg [3:0]bc_up;			// Rising SCL edge counter
reg [15:0]m_start_count;// Counter for generating START condition of MASTER
reg [15:0]rs_count;		// Counter for generating RESTART condition of MASTER
reg [7:0]rx_shift_data;	// Shifting data of the RECEIVER
reg [8:0]tx_shift_data;	// Shifting data of the TRANSMITER
reg [2:0]cur_state;		// Current state of FSM
reg [2:0]next_state;	// Next state of FSM
reg [7:0]byte_count;	// Byte transfer counter
reg [31	:0]ics_counter;	// Counter for generating STOP condition of MASTER
reg [10:0]s_scl_counter;// SCL counter for finding clock dividing number in SLAVER
reg [10:0]s_cd;			// Slaver clock dividing number
reg [10:0]bcd9_counter;	// Counter initialized by 9'th falling clock edge
reg [4:0]ics_enable; 	// Clock stop delay signal

reg scl1;				// SCL 1-pclock-cycle-delay
reg sda1;				// SDA 1-pclock-cycle-delay
reg mrs2, mrs3;			// Restart interval delay
reg apb_ms1;
reg apb_ms2; 
reg apb_ms3;
reg m_stop1;
reg mrs_one1;
reg mrs_one2;
reg mrs_three1;
reg mrs_three2;
reg s_r1;
reg s_w1;
reg m_r1;
reg m_w1;


//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------

// Detecting falling clock edge
assign scl_down 		= ~scl & scl1;
// Detecting rising clock edge
assign scl_up 			= scl & ~scl1;

// Detecting falling data edge
assign sda_down 		= ~sda & sda1;
// Detecting rising data edge
assign sda_up 			= sda & ~sda1; 

assign clock_rate = apb_csel[1] ? (apb_csel[0] ? 15 : 125) : (apb_csel[0] ? 50 : 500);
// One/two SCL cycle
assign one_cycle 	= clock_rate;
assign two_cycle 	= 2 * clock_rate;

assign bcd0 		= (bc_down ==0);
assign bcd9 		= (bc_down ==9);

assign bcu0 		= (bc_up ==0);
assign bcu9 		= (bc_up ==9);

// Rising clock edge counter complete
assign bc_up_complete 	= bcu9;
// Falling clock edge counter complete
assign bc_down_complete = bcd9;

// Detecting falling/rising edge of 'master/slaver' signal
assign apb_ms_down 		= ~apb_ms & apb_ms3;
assign apb_ms_up		= apb_ms & ~apb_ms3;

// Falling edge of 'mrs_one'
assign mrs_one_down 	= ~mrs_one & mrs_one2;
assign mrs_three_down 	= ~mrs_three & mrs_three2;

// START condition of SLAVE
assign s_start 			= scl & sda_down & ~apb_ms;
// STOP condition of SLAVE
assign s_stop 			= scl & sda_up & ~apb_ms;

// Writing signal to Receiving FIFO
assign i_rxff_wr 		= (m_fsm_receive | s_fsm_receive) & (bc_up == 8) & scl_down;

// Reading signal to Transmiting FIFO
assign i_txff_rd		= ~txff_empty & (((s_fsm_firstbyte & rx_shift_data[0]) | (s_fsm_transmit | ((m_fsm_transmit |m_fsm_firstbyte) & ~apb_rw)))& scl_up & (bc_down == 8)) ;

// Checking ACK bit returning by the receiver
assign m_ack_ok 		= scl_up & bcd0 ? ((~(~sda & (m_fsm_transmit | m_fsm_firstbyte))) & ~m_fsm_receive) : 1'b1;
assign s_ack_ok 		= s_fsm_transmit & scl_up & ~sda & bcd0;

// Changing state signal for the master 
assign m_r				= apb_rw & ~m_ack_ok;
assign m_w				= ~apb_rw & ~m_ack_ok;

// Slaver checks the address transmitted in the data line
assign s_right_addr 	= (byte_count != 0) & s_fsm_firstbyte & (rx_shift_data[7:1] == apb_add[6:0]);

// Changing state signal for the slaver
assign s_r				= s_right_addr & (bcu9) & ~rx_shift_data[0] & (byte_count != 0) ; 	// to slave receive
assign s_w				= s_right_addr & (bcu9) & rx_shift_data[0] & (byte_count != 0);		// to slave transmit

// Enable signal for shifting data in the transmitter and receiver
assign m_tx_shift_en 	= scl_down & (m_fsm_firstbyte | m_fsm_transmit) & ~(bc_up == 8);
assign m_rx_shift_en	= scl_up & m_fsm_receive & ~( bcd0 | bcd9);

assign s_tx_shift_en 	= scl_down & (s_fsm_firstbyte | s_fsm_transmit) & ~(bc_up == 8);
assign s_rx_shift_en 	= scl_up & (s_fsm_firstbyte | s_fsm_receive) & ~(bc_up == 8);

// Initial value for transmitting shift register
always @(posedge pclk )
begin
 if (bc_up==6)
	s_init_value 	<=  txff_data[7:0] ;
	else 
	s_init_value 	<=	s_init_value;
end
assign m_init_value		= (m_fsm_firstbyte &(byte_count==0)) ? {apb_tadd [6:0]  , apb_rw } : txff_data [7:0] ;

// STOP interval of TRANSMITTING MASTER 
//assign m_stop 			= apb_ms & ~apb_sp & bcu0 & (byte_count > 0);
assign m_stop 			= apb_ms & ~apb_sp & bcd0 & (byte_count !=0);
// Rising edge of 'm_stop' - stop condition
assign m_stop_up 		= m_stop & ~m_stop1;
// STOP combined condition generated by MASTER 
assign ics_en 	 		= m_stop_up | (m_ack_ok & scl_up & bcd0 & (m_fsm_firstbyte | m_fsm_transmit)) ;
assign ics_one 			= (ics_counter >0) & (ics_counter < one_cycle);
assign ics_two 			= (ics_counter >0) & (ics_counter < two_cycle);
assign ics_three		= (ics_counter >0) & (ics_counter < one_cycle * 3);

// Interval for generating restart condition
assign m_rs_interval	= apb_rs & bcd0;
// Restart signal 
assign m_restart		= m_rs_interval & ~mrs3;
// Restart signal to Clock Generator
assign i_mrs	= mrs_three_down;
// Signal for clearing 'reset counter'
assign rs_clr			= rs_count == (one_cycle *3+4);
// Interval of one/two/three SCL cycle for restarting 
assign mrs_one 			= (rs_count >0) & (rs_count < one_cycle);
assign mrs_two 			= (rs_count >0) & (rs_count < two_cycle);
assign mrs_three		= (rs_count >0) & (rs_count < (one_cycle*3)+1 );

// Busy in transmitting/ receiving operation
assign i_tx_busy 		= s_tx_busy | m_tx_busy;
assign i_rx_busy 		= s_rx_busy | m_rx_busy;

// Completing signal for start counter of MASTER
assign start_complete	= (m_start_count == (2 * clock_rate) );

// Enable signal to Clock Generator
assign i_clock_en		= ((m_start_count >= 1) & (m_start_count <= one_cycle)) | (mrs_three & ~mrs_two);
// Disable signal to Clock Generator
assign i_clock_stop		= apb_ms & (ics_counter == one_cycle) | mrs_one_down;
// Clearing 'stop counter' signal
assign ics_clr 			= ics_counter == (one_cycle * 3);

// Restart detecting signal for SLAVER
assign s_rs_detect 		= (bcd9_counter > s_cd);
// Stop detecting signal for SLAVER
assign s_stop_detect = ~apb_ms & (bcd9_counter == (s_cd*5)>>2);

// Interval for returning ACK bit
assign ack_return 	= ics_one | (((bcd0 | bcd9) & ~s_rs_detect  & (s_fsm_firstbyte | s_fsm_receive | (apb_sp & m_fsm_receive & (byte_count!=1)))) | ((s_fsm_transmit|s_fsm_receive)&(byte_count==1)));

assign s_firstbyte_to_idle		= (bcd0 & scl_up) &(~s_right_addr | s_ack_ok);
// Writing data to receiving FIFO
assign rxff_din 		= rx_shift_data[7:0];

// Output of FSM
assign m_tx_busy	= ~cur_state[2] & cur_state[0];
assign m_rx_busy	= ~cur_state[2] & cur_state[1] & ~cur_state[0];
//assign m_fsm_idle	= ~cur_state[2] & ~cur_state[1] & ~cur_state[0];
assign m_fsm_receive	= ~cur_state[2] & cur_state[1] & ~cur_state[0];
assign m_fsm_firstbyte	= ~cur_state[2] & ~cur_state[1] & cur_state[0];
assign m_fsm_transmit	= ~cur_state[2] & cur_state[1] & cur_state[0];

assign s_tx_busy	= cur_state[2] & cur_state[1] & cur_state[0];
assign s_rx_busy	= cur_state[2] & (cur_state[1] ^ cur_state[0]);
assign s_fsm_idle	= cur_state[2] & ~cur_state[1] & ~cur_state[0];
assign s_fsm_receive	= cur_state[2] & cur_state[1] & ~cur_state[0];
assign s_fsm_firstbyte	= cur_state[2] & ~cur_state[1] & cur_state[0];
assign s_fsm_transmit	= cur_state[2] & cur_state[1] & cur_state[0];

// High impedance condition of SDA
assign hiz 		=  m_hiz | s_hiz;
assign m_hiz 	=  apb_ms & ((m_fsm_receive & (~(bcd0 | bcd9) | (bcu0 & (byte_count==1)))) | ((m_fsm_firstbyte | m_fsm_transmit) & (bcd0 | bcd9)) |mrs_one_down);
assign s_hiz 	= ~apb_ms & ((s_rs_detect & ~apb_ms)	| s_fsm_idle | ((s_fsm_receive | s_fsm_firstbyte) & (~(bcd0 | bcd9) | (byte_count ==0))) | (s_fsm_transmit & (bcd0 | bcd9 | byte_count==1)));

// '1'b0' condition of SDA
assign zero		= (ack_return & ~rxff_ov) | ((i_clock_en  | (~ics_one & ics_two ) | (mrs_one | mrs_three_down) )& apb_ms);

// '1'b1' condition of SDA
assign one		= (apb_ms &ics_three & ~ics_two)  | (ack_return &  rxff_ov) | (apb_ms & mrs_two & ~mrs_one) ;

// Serial CLock Line
assign scl		= apb_ms ? i_clk : (~prst_n ? 1'b1 : (rxff_ov ? 1'b0 : 1'bz))	;

// Serial Data Line
assign sda 		= one ? 1'b1 : (zero  ? 1'b0 : (hiz ? 1'bz: tx_shift_data[8]));


//------------------------------------------------------------
//-- FINITE STATE MACHINE
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n) cur_state <= #`DELAY M_IDLE;
	else if (~apb_en) begin
		if (apb_ms) cur_state <= #`DELAY M_IDLE;
		else cur_state <= #`DELAY S_IDLE;
	end

	else if (apb_ms_up)		cur_state <= #`DELAY M_IDLE;
	else if (apb_ms_down) 	cur_state <= #`DELAY S_IDLE;
	
	else cur_state <= #`DELAY next_state;
end

always @(*)
begin
	case (cur_state)
	// MASTER FSM
		M_IDLE: 
			if (apb_sp) next_state <= #`DELAY M_FIRSTBYTE;
			else next_state <= #`DELAY cur_state;
		M_FIRSTBYTE:
			if(m_w1 )			next_state <= #`DELAY M_TRANSMIT;
			else if(m_r1 )	next_state <= #`DELAY M_RECEIVE;
			else if (bcd0 & scl_up & m_ack_ok)
							next_state <= #`DELAY M_IDLE;
			else 			next_state <= #`DELAY cur_state;
		M_TRANSMIT:
			if(ics_enable[4])next_state <= #`DELAY M_IDLE;
			else if(i_clock_stop)	
							next_state <= #`DELAY M_IDLE;
			else 			next_state <= #`DELAY cur_state;
		M_RECEIVE:
			if(m_stop)		next_state <= #`DELAY M_IDLE;
			else if(i_clock_stop)	
							next_state <= #`DELAY M_IDLE;
			else 		next_state <= #`DELAY cur_state;
	
	// SLAVER FSM
		S_IDLE:
			if(s_start) next_state <= #`DELAY S_FIRSTBYTE;
			else next_state <= #`DELAY cur_state;
		S_FIRSTBYTE:
			if(s_w1)		next_state <= #`DELAY S_TRANSMIT;
			else if(s_r1)	next_state <= #`DELAY S_RECEIVE;
			else if (s_firstbyte_to_idle)
							next_state <= #`DELAY S_IDLE;
			else 			next_state <= #`DELAY cur_state;
		S_TRANSMIT:
			if(s_start)		next_state <= #`DELAY S_FIRSTBYTE;
			else if((~s_ack_ok & scl_up & bcd0) | s_stop)	
							next_state <= #`DELAY S_IDLE;
			else 			next_state <= #`DELAY cur_state;
		S_RECEIVE:
			if(s_stop)		next_state <= #`DELAY S_IDLE;
			else if(s_start)	
							next_state <= #`DELAY S_FIRSTBYTE;
			else 		next_state <= #`DELAY cur_state;
	endcase
end

//------------------------------------------------------------
//-- RISING CLOCK EDGE COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n) 
		bc_up 		<= #`DELAY 4'b0;
	else begin
		case ({scl_up , bc_up_complete})
			2'b00: 	bc_up <= #`DELAY  bc_up;
			2'b01: 	bc_up <= #`DELAY  4'b0;
			2'b10: 	bc_up <= #`DELAY  bc_up + 4'd1;
			2'b11: 	bc_up <= #`DELAY  4'b0;
			default:bc_up <= #`DELAY  bc_up;
		endcase
	end
end

//------------------------------------------------------------
//-- FALLING CLOCK EDGE COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n) 
		bc_down		<= #`DELAY 4'b0;
	else begin
		case ({scl_down , bc_down_complete})
			2'b00: 	bc_down <= #`DELAY  bc_down;
			2'b01: 	bc_down <= #`DELAY  4'b0;
			2'b10: 	bc_down <= #`DELAY  bc_down + 4'd1;
			2'b11: 	bc_down <= #`DELAY  4'b0;
			default:bc_down <= #`DELAY  bc_down;
		endcase
	end
end


//------------------------------------------------------------
//-- BYTE COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		byte_count <= #`DELAY 8'b0;
	else begin
		case ({((bc_up==0)&scl_down) , (ics_en | m_restart | s_start)})
			2'b00: 	byte_count <= #`DELAY  byte_count;
			2'b01: 	byte_count <= #`DELAY  8'b0;
			2'b10: 	byte_count <= #`DELAY  byte_count + 8'd1;
			2'b11: 	byte_count <= #`DELAY  8'b0;
			default:byte_count <= #`DELAY  byte_count;
		endcase
	end
end

//------------------------------------------------------------
//-- SLAVER CLOCK COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		s_scl_counter <= #`DELAY 10'b0;
	else begin
		if (scl_up) s_scl_counter  <= #`DELAY 10'b0;
		else s_scl_counter <= #`DELAY s_scl_counter + 10'd1;
	end
end

//------------------------------------------------------------
//-- SLAVER CLOCK DIVIDENT
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		s_cd <= #`DELAY 10'b0;
	else begin
		if (scl_up) s_cd  <= #`DELAY s_scl_counter;
	end
end

//------------------------------------------------------------
//-- START COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		m_start_count <= #`DELAY 16'b0;
	else begin
		case ({apb_sp , start_complete })
			2'b00: 	m_start_count <= #`DELAY  16'b0;
			2'b01: 	m_start_count <= #`DELAY  m_start_count;
			2'b10: 	m_start_count <= #`DELAY  m_start_count + 1'd1;
			2'b11: 	m_start_count <= #`DELAY  m_start_count;
			default:m_start_count <= #`DELAY  m_start_count;
		endcase
	end
end


//------------------------------------------------------------
//-- RESET COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		rs_count <= #`DELAY 16'b0;
	else begin
		case ({m_restart , rs_clr | (~apb_rs & bc_down>2)})
			2'b00: 	rs_count <= #`DELAY  rs_count + 1'd1;
			2'b01: 	rs_count <= #`DELAY  rs_count;
			2'b10: 	rs_count <= #`DELAY  16'b0;
			2'b11: 	rs_count <= #`DELAY  16'b0;
			default:rs_count <= #`DELAY  rs_count;
		endcase
	end
end

//------------------------------------------------------------
//-- STOP CONDITION DETECTION
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		bcd9_counter <= #`DELAY 10'b0;
	else begin
		case ({scl_down, s_stop_detect})
			2'b00: 	bcd9_counter <= #`DELAY  bcd9_counter + 1'b1;
			2'b01: 	bcd9_counter <= #`DELAY  bcd9_counter;
			2'b10: 	bcd9_counter <= #`DELAY  1'b0;
			2'b11: 	bcd9_counter <= #`DELAY  1'b0;
			default:bcd9_counter <= #`DELAY  bcd9_counter;
		endcase
	end
end

//------------------------------------------------------------
//-- STOP COUNTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		ics_counter <= #`DELAY 10'b0;
	else begin
		case ({ics_en, (ics_clr | apb_sp) & byte_count!=0 })
			2'b00: 	ics_counter <= #`DELAY  ics_counter + 1'b1;
			2'b01: 	ics_counter <= #`DELAY  ics_counter;
			2'b10: 	ics_counter <= #`DELAY  1'b0;
			2'b11: 	ics_counter <= #`DELAY  1'b0;
			default:ics_counter <= #`DELAY  ics_counter;
		endcase
	end
end


//------------------------------------------------------------
//-- RECEIVING SHIFT REGISTER
//------------------------------------------------------------
always @(posedge pclk)
begin
	if(m_rx_shift_en | s_rx_shift_en)
		rx_shift_data <= #`DELAY { rx_shift_data[6:0] , sda};	
end


//------------------------------------------------------------
//-- TRANSMITTING SHIFT REGISTER
//------------------------------------------------------------
always @(posedge pclk or negedge prst_n)
begin
	if(~prst_n)
		tx_shift_data <= #`DELAY {9{1'b1}};	
	else 
	begin
		if(apb_ms)
		begin
			case ({(bc_down_complete | (m_fsm_firstbyte &(byte_count==0)) | m_restart)  , m_tx_shift_en})
			2'b00: 	tx_shift_data <= #`DELAY  tx_shift_data;
			2'b01: 	tx_shift_data <= #`DELAY  { tx_shift_data[7:0] , 1'b1 };
			2'b10: 	tx_shift_data <= #`DELAY  {1'b1,m_init_value};
			2'b11: 	tx_shift_data <= #`DELAY  { tx_shift_data[7:0] , 1'b1 };
			default:tx_shift_data <= #`DELAY  tx_shift_data;
		endcase
		end
		else
		begin
			case ({bc_up_complete , s_tx_shift_en})
			2'b00: 	tx_shift_data <= #`DELAY  tx_shift_data;
			2'b01: 	tx_shift_data <= #`DELAY  {tx_shift_data[7:0] , 1'b1};
			2'b10: 	tx_shift_data <= #`DELAY  s_init_value;
			2'b11: 	tx_shift_data <= #`DELAY  s_init_value;
			default:tx_shift_data <= #`DELAY  tx_shift_data;
		endcase
		end
	end
end


always @(posedge pclk)
begin
if (~prst_n)
	begin
		scl1 		<= #`DELAY 1'b0;
		sda1 		<= #`DELAY 1'b0;
		m_stop1 	<= #`DELAY 1'b0;
		mrs2 		<= #`DELAY 1'b0;
		mrs3 		<= #`DELAY 1'b0;
		apb_ms1		<= #`DELAY 1'b0;
		apb_ms2		<= #`DELAY 1'b0;
		apb_ms3		<= #`DELAY 1'b0;
		ics_enable[0]		<= #`DELAY 1'b0;
		ics_enable[1]		<= #`DELAY 1'b0;
		ics_enable[2]		<= #`DELAY 1'b0;
		ics_enable[3]		<= #`DELAY 1'b0;
		ics_enable[4]		<= #`DELAY 1'b0;
		mrs_one1	<= #`DELAY 1'b0;
		mrs_one2	<= #`DELAY 1'b0;
		s_r1		<= #`DELAY 1'b0;
		s_w1		<= #`DELAY 1'b0;
		m_r1		<= #`DELAY 1'b0;
		m_w1		<= #`DELAY 1'b0;
	end
	else begin
		scl1 		<= #`DELAY scl;
		sda1 		<= #`DELAY sda;
		m_stop1 	<= #`DELAY m_stop;
		mrs2 		<= #`DELAY m_rs_interval;
		mrs3 		<= #`DELAY mrs2;
		apb_ms1		<= #`DELAY apb_ms;
		apb_ms2		<= #`DELAY apb_ms1;
		apb_ms3		<= #`DELAY apb_ms2;
		ics_enable[0]		<= #`DELAY i_clock_stop;
		ics_enable[1]		<= #`DELAY ics_enable[0];
		ics_enable[2]		<= #`DELAY ics_enable[1];
		ics_enable[3]		<= #`DELAY ics_enable[2];
		ics_enable[4]		<= #`DELAY ics_enable[3];
		mrs_one1	<= #`DELAY mrs_one;
		mrs_one2	<= #`DELAY mrs_one1;
		mrs_three1	<= #`DELAY mrs_three;
		mrs_three2	<= #`DELAY mrs_three1;
		s_r1		<= #`DELAY s_r;
		s_w1		<= #`DELAY s_w;
		m_r1		<= #`DELAY m_r;
		m_w1		<= #`DELAY m_w;
	end
end

endmodule


