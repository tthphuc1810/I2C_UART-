
//------------------------------------------------------------
//-- UART BAUD RATE GENERATOR
//------------------------------------------------------------

`include "n2v_define.v"

module uart_baud (
	// Outputs
	brg_tx_shift,brg_rx_shift,
	// Inputs
	pclk,prst_n,apb_brg, apb_en,apb_bsel);

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input pclk,prst_n;
input apb_en;
input apb_bsel;
input [7:0]apb_brg;
 
//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output brg_tx_shift;
output brg_rx_shift;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [7:0] brg_rxcounter ;
reg [7:0] brg_txcounter ;

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire clr;
wire clr_txcounter ;// set lai bit 
wire clr_rxcounter;// set lai bit
wire [7:0]sel_num;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign clr 				= brg_rx_shift;
assign clr_txcounter 	= ((!apb_en) | brg_tx_shift);
assign clr_rxcounter 	= ((!apb_en) | clr);
assign sel_num 			= (apb_bsel)?8'd7:8'd15;
assign brg_tx_shift 	= (brg_txcounter ==sel_num) & brg_rx_shift;
assign brg_rx_shift 	= brg_rxcounter == apb_brg;


always @(posedge pclk,negedge prst_n) // can than voi synchronous reset
	if(!prst_n)
	brg_rxcounter <= #`DELAY 0;
	else if (clr_rxcounter)
	brg_rxcounter <= #`DELAY 0;
	else 
	brg_rxcounter <= #`DELAY brg_rxcounter +8'd1;



always @(posedge pclk,negedge prst_n) // can than voi synchronous reset
	if (!prst_n)
	brg_txcounter <= #`DELAY 0;
	else if (clr_txcounter)
	brg_txcounter <= #`DELAY 0;
	else if (brg_rx_shift)
	brg_txcounter <= #`DELAY brg_txcounter +8'd1;

endmodule