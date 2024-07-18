//APB Master
`include "n2v_define.v"
module apb_master (
  
pclk, 
prst_n,
data_in,			//input data 
data_sel,			//select data/addr
data_wr,			//apply data/addr
apb_we,				//apb_write enable
apb_re,				//read enable
prdata,    

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
input     [31:0] prdata;

//----Output----
output 			pwrite;
output 	 		penable;
output 	 		psel;
output 	reg	[31:0]	paddr;
output 	reg [31:0]	pwdata; 

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
reg 	[2:0] 	current_state;
reg 	[2:0] 	next_state;
wire 			write;
wire 			read;
  
  // FIFO SIGNAL
wire aff_wr,     
     aff_rd,
     aff_full,
     aff_empty;
  
reg [7:0] aff_data_in;
wire [7:0] aff_data_out;      
wire fifo_we, fifo_re;
reg [4:0]wptr,rptr;
reg [7:0]memory[15:0];
reg wr1, rd1;
wire wr_m, rd_m;
reg underflow;
reg overflow;
reg fifo_we1, fifo_we2;

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
assign data_wr_edge = data_wr_f2 & ~data_wr_f3;		
assign pwdata_sel 	= data_wr_edge & data_sel;
assign paddr_sel	= data_wr_edge & ~data_sel;

//----data
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			pwdata [31:0] <= #`DELAY 32'b0;
		else 
		  case ({pwdata_sel, paddr[6:0] == 7'h0C})
		    2'b10: pwdata <= {24'b0, data_in};
		    2'b00: pwdata <= pwdata;
		    2'b01: pwdata <= aff_data_out;
		    2'b11: pwdata <= aff_data_out;
		  endcase
	end
//----address
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n)
			paddr [31:0] <= #`DELAY 32'b0;
		else 
			if (paddr_sel)
		    paddr <= {24'b0, data_in};
      else paddr <= paddr;
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
assign apb_we_edge = apb_we_f2 & ~apb_we_f3;
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
assign apb_re_edge = apb_re_f2 & ~apb_re_f3;	
//----FSM
always @ (posedge pclk, negedge prst_n)
	begin
		if (~prst_n) 
			current_state <= #`DELAY IDLE;
		else 
			current_state <= #`DELAY next_state;
	end	
//-----STATE TRANSFER
always @ (*)
	begin
		case (current_state)
			IDLE: 
				begin
					if (apb_we_edge) 
						next_state 	= WRITE;
					else if (apb_re_edge) 
								next_state 	= READ;
				else next_state = IDLE;
				end	
							
			WRITE:
				begin
					next_state = IDLE;
				end
			READ:
				begin
					next_state = IDLE;
				end
	 default: next_state = IDLE;
		endcase
	end 
//OUTFSM
assign read = current_state[0]	& ~current_state[1];
assign write = ~current_state[0]	& current_state[1];
assign psel = (read|write)?1'b1:1'b0;
assign pwrite = (write)?1'b1:1'b0;
assign penable = (read|write)?1'b1:1'b0;

//--------------------------------
//-------CONFIG FIFO--------------
//--------------------------------

//  MEMORY
  always @(posedge pclk) 
    begin
    if((paddr[6:0] == 7'h2C) | (paddr[6:0] == 7'h0C)) 
        aff_data_in <= prdata [7:0];
	else
		aff_data_in <= aff_data_in;
	
  end
//assign aff_data_in = ((paddr[6:0] == 7'h2C) | (paddr[6:0] == 7'h0C))?prdata [7:0]:aff_data_in;
//  MEMORY
  always @(posedge pclk) 
    begin

      if(fifo_we) 
        memory[wptr[4:0]] = aff_data_in;
  end
  
  assign aff_data_out = memory[rptr[4:0]];
                     
//  READ POINTER & WRITE POINTER 
  always @(posedge pclk or negedge prst_n) 
    begin
      if(~prst_n) begin
        wptr = 'b0;
        rptr = 'b0;
        end
      else begin
        if(fifo_re) 
          rptr = rptr + 1'b1;
        else 
          rptr = rptr;
          
        if(fifo_we2) 
          wptr = wptr + 1'b1;
        else 
          wptr = wptr;
        end
    end
          
//aff_full
  assign fifo_we = ~(aff_full) & wr_m;
  assign aff_full = (wptr[4] ^ rptr[4]) & (wptr[3:0] == rptr[3:0]);
  
//aff_empty
  assign fifo_re = ~aff_empty & rd_m;
  assign aff_empty = ~(wptr[4] ^ rptr[4]) & (wptr[3:0] == rptr[3:0]);
  
//OVERFLOW    
  always @(posedge pclk) 
    begin
      if(~prst_n)
        begin
          overflow = 1'b0; 
        end
      else 
    begin
      if(~fifo_re & aff_full & wr_m)
        overflow = 1'b1;
      else if (fifo_re)
        overflow = 1'b0;
      else
        overflow = overflow;
    end
    end    
    
//UNDERFLOW    
  always @(posedge pclk) 
    begin
      if(~prst_n)
        begin
          underflow = 1'b0; 
        end
      else 
    begin
      if(~fifo_we & aff_empty & rd_m)
        underflow = 1'b1;
      else if (fifo_we)
        underflow = 1'b0;
      else
        underflow = underflow;
    end
    end 
 
 
 //GIAI QUYET NUT NHAN
  assign aff_wr = read & ((paddr[6:0] == 7'h0C)|(paddr[6:0] == 7'h2C)) ;
  assign aff_rd = write & (paddr[6:0] == 7'h0C);
  assign wr_m = aff_wr & ~wr1;
  assign rd_m = aff_rd & ~rd1;
  always @(posedge pclk)
    begin
      fifo_we1 <= fifo_we;
      fifo_we2 <= fifo_we1;
      wr1 <= aff_wr;
      rd1 <= aff_rd;
    end
    endmodule