//APB Master
`include "n2v_define.v"

module apb_master_1 (
	// input 
pclk, 
prst_n,
data_in,			//input data 
data_sel,			//select data/addr
data_wr,			//apply data/addr
apb_we,				//apb_write enable
apb_re,				//read enable
prdata,
data_out,
	//output 
pwrite,			
penable,
psel,
pwdata,				//output data
paddr			//output address
);
//-----PARAMETERS----
parameter 			IDLE 	= 2'b00;
parameter 			READ 	= 2'b01;
parameter 			WRITE 	= 2'b10;
//-----Input-----
input 				pclk, prst_n;
input				data_sel;
input 				data_wr;
input 		[7:0]	data_in;
input 				apb_we;
input 				apb_re;
input		[31:0]	prdata;

//----Output----
output 	reg			pwrite;
output 	reg 		penable;
output 	reg 		psel;
output 	reg	[31:0]	paddr;
output 	reg [31:0]	pwdata;
output 	reg [7:0]	data_out;

//----Internal signals---
reg				data_wr_f1;			//data_wr after ff 1
reg				data_wr_f2;			//data_wr after ff 2
reg				data_wr_f3;			//data_wr after ff 3
wire			data_wr_edge;		//data_wr edge
	//----WRITE ENABLE
reg				apb_we_f1;			//apb_we after ff 1
reg				apb_we_f2;			//apb_we after ff 2
reg				apb_we_f3;			//apb_we after ff 3
wire			apb_we_edge;		//apb_we edge
	//-----READ ENABLE
reg				apb_re_f1;			//apb_re after ff 1
reg				apb_re_f2;			//apb_re after ff 2
reg				apb_re_f3;			//apb_re after ff 3
wire			apb_re_edge;		//apb_re edge
	//-----SELLECT
wire 			paddr_sel;		//select address
wire 			pwdata_sel;			//select data
	//------FSM
reg 	[1:0] 	current_state;
reg 	[1:0] 	next_state;

always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			begin
				data_wr_f1 	<= #`DELAY 1'b0;
				data_wr_f2 	<= #`DELAY 1'b0;
				data_wr_f3 	<= #`DELAY 1'b0;
			end
		else
			begin
				data_wr_f1 	<= #`DELAY data_wr;
				data_wr_f2 	<= #`DELAY data_wr_f1;
				data_wr_f3 	<= #`DELAY data_wr_f2;
			end
	end
assign data_wr_edge = ~data_wr_f2 & data_wr_f3;		
assign pwdata_sel 	= data_wr_edge & data_sel;
assign paddr_sel	= data_wr_edge & ~data_sel;

//----data
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			pwdata [31:0] <= #`DELAY 32'b0;
		else 
			if (pwdata_sel)
				pwdata [31:0] <= #`DELAY {24'b0,data_in [7:0]};
	end
//----address
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			paddr [31:0] <= #`DELAY 31'b0;
		else 
			if (paddr_sel)
				paddr [31:0] <= #`DELAY {24'b0, data_in [7:0]};
	end
	
//----APB_WE EDGE DETECTION
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			begin
				apb_we_f1 	<= #`DELAY 1'b0;
				apb_we_f2 	<= #`DELAY 1'b0;
				apb_we_f3 	<= #`DELAY 1'b0;
			end
		else
			begin
				apb_we_f1 	<= #`DELAY apb_we;
				apb_we_f2 	<= #`DELAY apb_we_f1;
				apb_we_f3 	<= #`DELAY apb_we_f2;
			end
	end
assign apb_we_edge = ~apb_we_f2 & apb_we_f3;	

//----APB_RE EDGE DETECTION
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			begin
				apb_re_f1 	<= #`DELAY 1'b0;
				apb_re_f2 	<= #`DELAY 1'b0;
				apb_re_f3 	<= #`DELAY 1'b0;
			end
		else
			begin
				apb_re_f1 	<= #`DELAY apb_re;
				apb_re_f2 	<= #`DELAY apb_re_f1;
				apb_re_f3 	<= #`DELAY apb_re_f2;
			end
	end	
assign apb_re_edge = ~apb_re_f2 & apb_re_f3;	
	
//----FSM
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n) 
			current_state <= #`DELAY IDLE;
		else 
			current_state <= #`DELAY next_state;
	end	
//-----STATE TRANSFER
always @ (posedge pclk)
	begin
		case (current_state)
			IDLE: 
				begin
					psel 	<= 1'b0;
					penable	<= 1'b0;
					pwrite	<= 1'b0;
					if (apb_we_edge) 
						next_state 	<= WRITE;
					else 
						begin
							if (apb_re_edge) 
								begin
								next_state 	<= READ;
								data_out <= #`DELAY prdata[7:0];
								end
							else 
								begin
								next_state <= IDLE;
								data_out <= #`DELAY data_out;
								end
						end
				end	
						
								
			WRITE:
				begin
					psel	<= 1'b1;
					pwrite	<= 1'b1;
					penable	<= 1'b1;
					next_state <= IDLE;
				end
			READ:
				begin
					psel	<= 1'b1;
					pwrite	<= 1'b0;
					penable <= 1'b1;
					next_state <= IDLE;
				end
		default: next_state <= IDLE;
		endcase
	end 
	

endmodule
