//------------------------------------------------------------
//-- APB SLAVER INTERFACE
//------------------------------------------------------------

`include "n2v_define.v"
module i2c_apb(
	// Inputs
	prst_n		, pclk		, psel		, penable	, pwrite	, paddr		, pwdata, 
	rxff_data	, 	rxff_ov	, i_rx_busy	, i_tx_busy	, rxff_rxne	, txff_txnf	, i_mrs	,
	// Outputs
    prdata	, apb_ctx	, apb_crx		, apb_ms		, apb_en, 
	apb_csel, apb_tadd	, apb_txff_wr	, apb_rxff_rd	, i2c_if,
	apb_add	, apb_rw	, apb_sp		, apb_rs		, apb_data
	);

//------------------------------------------------------------
//-- INPUT SIGNAL
//------------------------------------------------------------			   
input prst_n;
input pclk;
input psel;
input penable;
input pwrite;
input [7:0] paddr;
input [31:0] pwdata;
input [7:0] rxff_data;
input rxff_ov;
input i_rx_busy;
input i_tx_busy;
input rxff_rxne;
input txff_txnf;
input i_mrs;
  
//------------------------------------------------------------
//-- OUTPUT SIGNAL
//------------------------------------------------------------
output reg [31:0] prdata;
output apb_ctx;
output apb_crx;
output apb_ms;
output apb_en;
output reg [6:0] apb_add;
output apb_rw;
output apb_sp;
output apb_rs;
output reg [7:0] apb_data;
output [1:0]apb_csel;
output reg [6:0] apb_tadd;
output apb_txff_wr;
output apb_rxff_rd;
output i2c_if;
  
//------------------------------------------------------------
//-- WIRE SIGNAL
//------------------------------------------------------------
wire apb_oie;
wire apb_tie;
wire apb_rie; 
wire apb_busy;
wire i2c_tf;
wire i2c_rf;
wire i2c_of; 
wire i2c_te;
wire i2c_re; 
wire we;
wire read; 
wire result;

//------------------------------------------------------------
//-- REGISTER SIGNAL
//------------------------------------------------------------  
reg con_we;
reg se_we;
reg add_we;
reg com_we;
reg dt_we;
reg ie_we;
reg cd_we;
reg tadd_we;
reg [6:0] apb_con;
reg [1:0] apb_se;
reg [2:0] apb_com;
reg [2:0] apb_ie;
reg [1:0] apb_clk;

//-----------------------------------------------
//-----------SIGNAL ASSIGNMENT-------------------
//-----------------------------------------------
assign apb_ctx =  apb_con[0];
assign apb_crx = apb_con[1];
assign apb_ms =  apb_con[2];
assign apb_en = apb_se[0];
assign apb_busy = i_tx_busy | i_rx_busy;
assign apb_rw = apb_com[0];
assign apb_sp = apb_com[1];
assign apb_rs = apb_com[2];
assign apb_csel = apb_clk;
assign apb_rie = apb_ie[1];
assign apb_tie = apb_ie[1];
assign apb_oie = apb_ie[0];
assign apb_txff_wr = dt_we & txff_txnf;
  
assign read = psel & penable &(~pwrite);
assign result = (paddr[7:0]==8'h2C);
assign apb_rxff_rd =read & result;

//-----------------INTERRUPT---------------------
assign i2c_te = txff_txnf;
assign i2c_re = rxff_rxne;
assign i2c_tf = apb_tie & i2c_te;
assign i2c_rf = apb_rie & i2c_re;
assign i2c_of = apb_oie & rxff_ov; 
assign i2c_if = i2c_tf | i2c_rf | i2c_of;	   
//----TIN HIEU DIEU KHIEN GHI VAO REG------------
assign we= psel & pwrite & penable;
  
always @(*) 
begin
	case(paddr[7:0])
	8'h1C:begin
		con_we= we;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
	8'h20: begin
		con_we= 1'b0;
		se_we = we;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
	8'h24: begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = we;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;    
	end
	8'h28: begin 
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = we;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
	8'h2C: begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = we;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
	8'h30: begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = we;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
	8'h3C: begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = we;
		tadd_we = 1'b0;
	end
	8'h40: begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = we;
	end
	default:begin
		con_we= 1'b0;
		se_we = 1'b0;
		add_we = 1'b0;
		com_we = 1'b0;
		dt_we = 1'b0;
		ie_we = 1'b0;
		cd_we = 1'b0;
		tadd_we = 1'b0;
	end
    endcase
end

//-----------------------------------------------
//----------- GHI VAO REGISTERS------------------
//-----------------------------------------------

  //CONTROL REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_con<= #`DELAY 3'd0;
    else if(con_we) 
		apb_con<= #`DELAY pwdata[2:0];
end

  //STATUS REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_se<= #`DELAY 2'd0;
    else if(se_we) 
		apb_se<= #`DELAY pwdata[1:0];
end

  //ADD REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_add<= #`DELAY 7'd0;
    else if(add_we) 
		apb_add<= #`DELAY pwdata[6:0];
end

  //COMMAND REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_com<= #`DELAY 3'd0;
    else if (i_mrs)
		apb_com[2] <= #`DELAY 1'b0;
	else if(com_we) 
		apb_com<= #`DELAY pwdata[2:0];
end

  //DATA REG
always @(posedge pclk) 
begin
	if(dt_we) 
		apb_data<= #`DELAY pwdata[7:0];
end

  //INTERRUPT ENABLE REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_ie<= #`DELAY 3'd0;
    else if(ie_we) 
		apb_ie<= #`DELAY pwdata[2:0];
end

  //CLOCK DEVIDER REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_clk<= #`DELAY 2'd0;
    else if(cd_we) 
		apb_clk<= #`DELAY pwdata[1:0];
end

  //TRANSMIT ADDRESS REG
always @(posedge pclk,negedge prst_n) 
begin
    if(~prst_n) 
		apb_tadd<= #`DELAY 7'd0;
    else if(tadd_we) 
		apb_tadd<= #`DELAY pwdata[6:0];
end
//-----------------------------------------------
//----------- DOC CAC REGISTERS------------------
//-----------------------------------------------

always @(*) 
begin
	casez(paddr[7:0])
		8'h1C:prdata={25'd0,apb_con[6:0]};
		8'h20:prdata={27'd0,apb_busy,rxff_rxne,txff_txnf,apb_se[1:0]};
		8'h24:prdata={25'd0,apb_add[6:0]};
		8'h28:prdata={29'd0,apb_com[2:0]};
		8'h2C:prdata={24'd0,rxff_data[7:0]};
		8'h30:prdata={29'd0,apb_ie[2:0]};
		8'h34:prdata={29'd0,i2c_re,i2c_te,rxff_ov};
		8'h38:prdata={29'd0,i2c_tf,i2c_rf,i2c_of};
		8'h3C:prdata={25'd0,apb_clk[1:0]};
		8'h40:prdata={25'd0,apb_tadd[6:0]};
		default: prdata = 32'bz;
    endcase
end


endmodule  
