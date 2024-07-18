
//------------------------------------------------------------
//-- UART APB INTERFACE
//------------------------------------------------------------

`include "n2v_define.v"

module uart_apb(
   // Outputs
   apb_af, 		apb_brg, 	apb_bsel, 		apb_crx,	apb_d9, 
   apb_data,	apb_en, 	apb_rxff_rd,	apb_rxt,    apb_tx_en, prdata,
   `ifdef  UART_COMBINE_INTERRUPT  uart_if,
   `else   uart_fif ,uart_oif,uart_pif, uart_rif,uart_tif,
   `endif
        
   // Inputs
   paddr, pclk, penable, prst_n, psel, pwdata, pwrite, rx_busy, 
   rx_data, rx_fe, rx_ov, rx_pe, rx_rxf, tx_busy, tx_txff_rd, rx_rxne
   );
   
//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------
input [31:0]	paddr;			// To apb_write_register_top1 of apb_write_register.v, ...
input			pclk;			// To apb_write_register_top1 of apb_write_register.v
input			penable;		// To apb_write_register_top1 of apb_write_register.v, ...
input			prst_n;			// To apb_write_register_top1 of apb_write_register.v
input			psel;			// To apb_write_register_top1 of apb_write_register.v, ...
input   [31:0]	pwdata;			// To apb_write_register_top1 of apb_write_register.v
input			pwrite;			// To apb_write_register_top1 of apb_write_register.v, ...
input			rx_busy;		// To apb_assign_signal_top4 of apb_assign_signal.v
input   [7:0]	rx_data;		// To apb_read_register_top2 of apb_read_register.v
input			rx_fe;			// To apb_interrupt_top3 of apb_interrupt.v
input			rx_ov;			// To apb_interrupt_top3 of apb_interrupt.v
input			rx_pe;			// To apb_interrupt_top3 of apb_interrupt.v
input			rx_rxf;			// To apb_interrupt_top3 of apb_interrupt.v
input			tx_busy;		// To apb_assign_signal_top4 of apb_assign_signal.v
input			tx_txff_rd;		// To apb_write_register_top1 of apb_write_register.v
input  			rx_rxne;
  
//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
  output		apb_af;			// From apb_assign_signal_top4 of apb_assign_signal.v
  output reg [7:0]		apb_brg;		// From apb_write_register_top1 of apb_write_register.v
  output		apb_bsel;		// From apb_assign_signal_top4 of apb_assign_signal.v
  output		apb_crx;		// From apb_assign_signal_top4 of apb_assign_signal.v
  output		apb_d9;			// From apb_assign_signal_top4 of apb_assign_signal.v
  output  [7:0]	apb_data;			// From apb_write_register_top1 of apb_write_register.v
  output		apb_en;			// From apb_assign_signal_top4 of apb_assign_signal.v
  output		apb_rxff_rd;		// From apb_assign_signal_top4 of apb_assign_signal.v
  output [1:0]	apb_rxt;		// From apb_assign_signal_top4 of apb_assign_signal.v
  output		apb_tx_en;		// From apb_assign_signal_top4 of apb_assign_signal.v
  output reg [31:0]		prdata;			// From apb_read_register_top2 of apb_read_register.v
  `ifdef UART_COMBINE_INTERRUPT output wire uart_if;
   wire uart_fif,uart_oif,uart_pif,uart_rif,uart_tif;	  
   `else 
   output wire uart_fif,uart_oif,uart_pif,uart_rif,uart_tif;
  `endif
  
//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------
reg [2:0]		apb_se;
reg [4:0]		apb_ie;
reg [7:0]		apb_con;

reg ie_we;
reg dt_we;
reg br_we;
reg se_we;
reg con_we;

reg [4:0]txff_wptr;
reg [4:0]txff_rptr;
reg [7:0]temp[15:0];

//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire apb_busy;
wire we;
wire rd;
wire real_br_en;
wire dt_we_txfifo;
wire dt_re_txfifo;
wire apb_ctx;
wire txff_txne;
wire txff_txnf; 
wire result_comp;

//------------------------------------------------------------
//-- SIGNAL ASSIGNMENT
//------------------------------------------------------------
assign rd = psel & penable &(~pwrite);
assign we = psel & pwrite & penable;
assign apb_ctx = con_we & pwdata[5];
assign apb_crx = con_we & pwdata[6];
assign apb_rxff_rd = rd & (paddr[4:0]==5'h0c);
assign apb_busy = tx_busy | rx_busy;
assign apb_en = apb_se[0];
assign apb_d9 = apb_se[1];
assign apb_bsel = apb_se[2];
assign apb_rxt[1:0] = apb_con[4:3];
assign apb_tx_en = apb_en & txff_txne;
assign apb_af = apb_con[0] & apb_en;
assign real_br_en=(~apb_en)&br_we;

//-- TRANSMITTING FIFO SIGNAL ASSIGNMENT
assign result_comp = (txff_rptr[3:0]==txff_wptr[3:0]);
assign apb_data=temp[txff_rptr[3:0]];
assign dt_we_txfifo=txff_txnf & dt_we;  
assign dt_re_txfifo= txff_txne & tx_txff_rd;
assign txff_txnf=~((txff_wptr[4]^txff_rptr[4]) & result_comp);
assign txff_txne=~( ~(txff_wptr[4]^txff_rptr[4]) & result_comp);

//------------------------------------------------------------
//-- INTERRUPT SIGNAL
//------------------------------------------------------------
assign uart_fif=apb_ie[4] & rx_fe;
assign uart_pif=apb_ie[3] & rx_pe;
assign uart_oif=apb_ie[2] & rx_ov;
assign uart_rif=apb_ie[1] & rx_rxf;
assign uart_tif=apb_ie[0] & txff_txne;
`ifdef  UART_COMBINE_INTERRUPT  
assign uart_if=uart_fif | uart_pif | uart_oif | uart_rif | uart_tif;
`endif 

//------------------------------------------------------------
//-- CONTROL SIGNAL
//------------------------------------------------------------
  always @(*) begin
    case(paddr[6:0])
      7'h00:begin
       con_we=we;
       se_we=1'b0;
       br_we=1'b0;
       dt_we=1'b0;
       ie_we=1'b0;
        end
      7'h04: begin
       con_we=1'b0;
       se_we=we;
       br_we=1'b0;
       dt_we=1'b0;
       ie_we=1'b0;
             end
      7'h08: begin
       con_we=1'b0;
       se_we=1'b0;
       br_we=we;
       dt_we=1'b0;
       ie_we=1'b0;
             end
      7'h0C: begin 
       con_we=1'b0;
       se_we=1'b0;
       br_we=1'b0;
       dt_we=we;
       ie_we=1'b0;
             end
      7'h10: begin
       con_we=1'b0;
       se_we=1'b0;
       br_we=1'b0;
       dt_we=1'b0;
       ie_we=we;
             end
      default:begin
       con_we=1'b0;
       se_we=1'b0;
       br_we=1'b0;
       dt_we=1'b0;
       ie_we=1'b0;
              end
    endcase
  end
  
//------------------------------------------------------------
//-- WRITE REGISTERS
//------------------------------------------------------------

//-- Control register
  always @(posedge pclk,negedge prst_n) begin
    if(~prst_n) apb_con<= #`DELAY 7'd0;
    else if(con_we) 
          apb_con<= #`DELAY pwdata[6:0];
    end
	
//-- Status register
  always @(posedge pclk,negedge prst_n) begin
    if(~prst_n) apb_se<= #`DELAY 3'd0;
    else if(se_we) 
          apb_se<=  #`DELAY pwdata[2:0];
    end
	
//-- Baud rate generator register
  always @(posedge pclk,negedge prst_n) begin
    if(~prst_n) apb_brg<=  #`DELAY 8'd0;
    else if(real_br_en) 
          apb_brg<=  #`DELAY pwdata[7:0];
    end
	
//-- Interrupt Enable Register
  always @(posedge pclk,negedge prst_n) begin
    if(~prst_n) apb_ie<=  #`DELAY 5'd0;
    else if(ie_we) 
          apb_ie<=  #`DELAY pwdata[4:0];
    end
	
//-- Data register
  always @(posedge pclk) begin
     if(dt_we_txfifo)
    temp[txff_wptr[3:0]]<=  #`DELAY pwdata[7:0];
  end


//------------------------------------------------------------
//-- READ REGISTERS
//------------------------------------------------------------
  always @(*) begin
    casez(paddr[7:0])
      8'h00:prdata = {25'd0,apb_con[6:0]};
      8'h04:prdata = {24'd0,apb_busy,rx_rxne,txff_txnf,2'd0,apb_se[2:0]};
      8'h08:prdata = {24'd0,apb_brg[7:0]};
      8'h0c:prdata = {24'd0,rx_data[7:0]};
      8'h10:prdata = {27'd0,apb_ie[4:0]};
      8'h14:prdata = {27'd0,rx_fe,rx_pe,rx_ov,rx_rxf,txff_txne};
      `ifdef  UART_COMBINE_INTERRUPT 
         8'h18:prdata=32'b0;
       `else 
        8'h18:prdata={27'd0,uart_tif,uart_pif,uart_oif,uart_rif,uart_tif};
       `endif
      default: prdata = 32'bz;
     endcase
  end

//------------------------------------------------------------
//-- TRANSMITTING FIFO
//------------------------------------------------------------

//-- Write pointer
  always @(posedge pclk, negedge prst_n) 
    begin
      if(~prst_n) txff_wptr<=  #`DELAY 5'd0;
      else 
        begin
          casez({dt_we_txfifo,apb_ctx})
             2'bz1: txff_wptr[4:0] <=  #`DELAY txff_rptr[4:0];
             2'b10: txff_wptr[4:0] <=  #`DELAY txff_wptr[4:0]+5'd1;
          endcase
        end
    end

//-- Read pointer
  always @(posedge pclk,negedge prst_n) 
    begin
      if(~prst_n) txff_rptr <=  #`DELAY 5'b0;
      else if(dt_re_txfifo)
        txff_rptr <=  #`DELAY txff_rptr+5'd1;
    end
    
endmodule

    

