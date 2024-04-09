//`include "ddr4_package.pkg"
//import ddr4_pkg::*;
`timescale 1ns/1ps

module tb_ram_controller();

reg [1:0] BA;
reg BG; 
reg WE_n; 
reg AP; 
reg ACT_n; 
reg RESET_n; 
reg CS_n; 
reg CKE; 
reg BURST_MODE;
reg [7:0] ROW_ADDRESS;
reg [5:0] COL_ADDRESS;
reg [15:0]DATAIN;	
wire [15:0]DATAOUT;

ram_controller dut(BG, BA, WE_n, AP, ACT_n, RESET_n, CS_n, CKE, ROW_ADDRESS, COL_ADDRESS, BURST_MODE, DATAIN, DATAOUT);

initial begin
	
/*-------------------------------------------------------------------------------
					CHECK RESET & CLOCK_ENABLE OFF AND ON
-------------------------------------------------------------------------------*/
/*		RESET_n = 1'b0;
		CKE = 1'b0;
		CS_n = 1'b0;
		ACT_n =1'b0;
		
	#10	ROW_ADDRESS = 8'h78;
		COL_ADDRESS = 6'b101101;
		BG = 0;
		BA = 0;
		WE_n = 1'b0;
	#10 CKE = 1'b1;
	#25 RESET_n = 1'b1;
	#15	DATAIN = 16'h7284;	

	#5  CS_n = 1'b1;
		AP = 1'b1;
		ACT_n = 1'b1;
	#50	$finish;
	*/
/*-------------------------------------------------------------------------------
					CHECK CHIP_SELECT OFF AND ON WRITE AND READ
-------------------------------------------------------------------------------*/	
/*		RESET_n = 1'b0;
		CKE = 1'b1;
	#15	RESET_n = 1'b1;	
		CS_n = 1'b1;
	#20 ACT_n =1'b0;
		ROW_ADDRESS = 8'h56;
		COL_ADDRESS = 6'b101110;
		BG = 1'b1;
		BA = 2'b11;
		WE_n = 1'b0;
	 	DATAIN = 16'h7284;
	#15	CS_n = 1'b0;
	#10 CS_n = 1'b1;
		WE_n = 1'b1;
		AP = 1'b1;
	#10 AP =1'b0;
	#20 CS_n = 1'b0;
	#5  CS_n =1'b1;
	#50 RESET_n = 1'b0;
	#50	$finish;*/
		
	
/*-------------------------------------------------------------------------------
					  		BURST_MODE WRITE/READ OPERATION
-------------------------------------------------------------------------------*/
/*----------------------------------WRITE--------------------------------------*/
	/*#10;
	CKE = 1'b1;
	RESET_n = 1'b0;
	CS_n = 1'b0;
	#10;
	ACT_n =1'b0;
	ROW_ADDRESS = 16'h0000;
	COL_ADDRESS = 10'h000;
	BG = 0;
	BA = 0;
	WE_n = 1'b0;
	BURST_MODE = 1'b1;
	AP=1'b0;
	#5;
	RESET_n = 1'b1;
	#20 DATAIN = 16'h7283; 
	#5 	DATAIN = 16'h7284;
	#5	DATAIN = 16'h7285;
	#5 	DATAIN = 16'h7286;
		CS_n = 1'b1;
		BURST_MODE = 1'b0;
	#25 AP = 1'b1;*/
	
/*----------------------------------READ---------------------------------------*/
/*	#10 AP = 1'b0;
		WE_n = 1'b1;
		BURST_MODE = 1'b1;
	#10	CS_n = 1'b0;
	
	
	#10 AP = 1'b0;				//for refresh check
	#20 RESET_n = 1'b0;
	#20 $finish;*/
	
/*------------------------------------------------------------------------------
			multiple write and read in same ROW of a bank(WRITE/READ)
------------------------------------------------------------------------------*/
//write
	/*	CKE = 1'b1;
		RESET_n = 1'b0;
		CS_n = 1'b1;
		ACT_n =1'b1;
		

	#15 RESET_n = 1'b1;
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b0;
	#5	ACT_n = 1'b1;
		WE_n = 1'b0;
		COL_ADDRESS = 6'b101100;
		DATAIN = 16'h72A4;
	#5	COL_ADDRESS = 6'b101101;
		DATAIN = 16'h72A5;
	#5	COL_ADDRESS = 6'b101110;
		DATAIN = 16'h72A6;
	#5	COL_ADDRESS = 6'b101111;
		DATAIN = 16'h72A7;
	#5	CS_n = 1'b1;
	#10	AP = 1'b1;
	#5  AP = 1'b0;
		ACT_n = 1'b0;
//read
	#5  CS_n = 1'b0;	
		WE_n = 1'b1;
	#5  COL_ADDRESS = 6'b101100;
		ACT_n = 1'b1;
	#5	COL_ADDRESS = 6'b101101;
	#5	COL_ADDRESS = 6'b101110;
	#5	COL_ADDRESS = 6'b101111;
	#5	CS_n = 1'b1;
	
	#25 RESET_n = 1'b0;
	#50 $finish;*/
/*------------------------------------------------------------------------------
			multiple write and read in different ROW/bank(WRITE/READ)
------------------------------------------------------------------------------*/
//write
	/*	CKE = 1'b1;
		RESET_n = 1'b0;
		CS_n = 1'b1;
		ACT_n =1'b1;
		
	#15 RESET_n = 1'b1;
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b0;
	#5	ACT_n = 1'b1;
		WE_n = 1'b0;
		COL_ADDRESS = 6'b101100;
		DATAIN = 16'h72A4;
	#5	CS_n = 1'b1;
		AP = 1'b1;
	#5	CS_n = 1'b0;
		ACT_n =1'b0;
		AP = 1'b0;
	#5	ROW_ADDRESS = 8'h63;
		BG = 1'b0;
		BA = 2'b11;
	#5	COL_ADDRESS = 6'b101111;
		DATAIN = 16'h72A7;
	#5  COL_ADDRESS = 6'b110001;
		DATAIN = 16'h72A8;
	#5	ACT_n =1'b1;
		CS_n = 1'b1;
	#10	AP = 1'b1;
	#5  AP =1'b0;
//read
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b0;
		WE_n = 1'b1;
	#5	ACT_n = 1'b1;
		COL_ADDRESS = 6'b101100;
	#5	CS_n = 1'b1;
		AP = 1'b1;
	#5	CS_n = 1'b0;
		ACT_n =1'b0;
		AP = 1'b0;
	#5	ROW_ADDRESS = 8'h63;
		BG = 1'b0;
		BA = 2'b11;
	#5	COL_ADDRESS = 6'b101111;
	#5  COL_ADDRESS = 6'b110001;
	#5	ACT_n =1'b1;
		CS_n = 1'b1;
		AP = 1'b1;
	#5  AP = 1'b0;
	
	#350 $finish;*/

/*------------------------------------------------------------------------------
		multiple write and read in same ROW of a bank(WRITE_A/READ_A)
------------------------------------------------------------------------------*/
//write
	/*	CKE = 1'b1;
		RESET_n = 1'b0;
		CS_n = 1'b1;
		ACT_n =1'b1;
		

	#15 RESET_n = 1'b1;
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b1;
	#5  WE_n = 1'b0;
		COL_ADDRESS = 6'b101100;
		DATAIN = 16'h72A4;
	#15	COL_ADDRESS = 6'b101111;
		DATAIN = 16'h72A7;
	#5	ACT_n = 1'b1;
		AP = 1'b0;
		CS_n = 1'b1;
//read
	#15 ACT_n = 1'b0;
		WE_n = 1'b1;
		CS_n = 1'b0;
		AP = 1'b1;
	#5  COL_ADDRESS = 6'b101100;
	#15	COL_ADDRESS = 6'b101111;
	#10 CS_n = 1'b1;
		ACT_n = 1'b1;	
	#25 RESET_n = 1'b0;
	#50 $finish;*/

/*------------------------------------------------------------------------------
		multiple write and read in different ROW of a bank(WRITE_A/READ_A)
------------------------------------------------------------------------------*/
//write
/*		CKE = 1'b1;
		RESET_n = 1'b0;
		CS_n = 1'b1;
		ACT_n =1'b1;
		

	#15 RESET_n = 1'b1;
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b1;
	#5	WE_n = 1'b0;
		COL_ADDRESS = 6'b101100;
		DATAIN = 16'h72A4;
	#15	ROW_ADDRESS = 8'h13;
		BG = 1'b0;
		BA = 2'b11;
	#5	COL_ADDRESS = 6'b101111;
		DATAIN = 16'h72A7;
	#5	CS_n = 1'b1;	
	#15	ACT_n =1'b1;
	
//read
	#10	CS_n = 1'b0;
		ACT_n =1'b0;
		ROW_ADDRESS = 8'h78;
		BG = 1'b1;
		BA = 2'b10;
		AP = 1'b1;
	#5	WE_n = 1'b1;
		COL_ADDRESS = 6'b101100;
	#15	ROW_ADDRESS = 8'h13;
		BG = 1'b0;
		BA = 2'b11;
	#5	COL_ADDRESS = 6'b101111;
	#5	CS_n = 1'b1;	
	#15	ACT_n =1'b1;	
		
	#25 RESET_n = 1'b0;
	#50 $finish;*/
	
end
endmodule	


	
	
	
