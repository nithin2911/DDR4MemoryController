/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------
													DESIGN OF DDR4 USING SYSTEM VERILOG 			  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------
The Project implements a DDR4 Memory Controller in System verilog which implements Open Page and Closed Page Policy.
The Project includes a burst mode operation to perfrom read/write data into multiple columns while giving a single address.
The Project includes a package to accept parametric data.
The Project does not include an extemsive testbench, it checks fir read/write operation into same bank, and into multiple banks with and without pre-charge active.
It also includes burst mode operation to read/write data from/into multiple columns while giving only one address input.	  			  
-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
`timescale 1ns/1ps
`include "ddr4_package.pkg"
import ddr4_pkg::*;
module ram_controller(input bit 						BG, 					//BANK GROUP BG0 BG1
							bit 	[1 : 0]				BA, 					//BANK ADDRESS BA0 BA1 BA2 BA3
							bit 						WE_n, 					//WRITE ENABLE (ACTIVE LOW)
							bit 						AP, 					//AUTO-PRECHARGE
							bit 						ACT_n, 					//ACTIVATE COMMAND INPUT (ACTIVE LOW)
							bit 						RESET_n, 				//RESET (ACTIVE LOW)
							bit 						CS_n, 					//CHIP SELECT (ACTIVE LOW)
							bit 						CKE, 					//CLOCK ENABLE
							bit 	[ROW_WIDTH-1 : 0] 	ROW_ADDRESS, 			//PROVIDES ROW ADDRESS
							bit 	[COL_WIDTH-1 : 0] 	COL_ADDRESS, 			//PROVIDES COLUMN ADDRESS
							bit 						BURST_MODE,				//BURST OPERATION 
							logic 	[WORD_SIZE-1 : 0] 	DATAIN, 				//DATA_INPUT TO WRITE
					 output logic 	[WORD_SIZE-1 : 0] 	DATAOUT	);				//DATA_OUT TO DISPLAY READ DATA

	bit clk_t;																	//DIFFERENTIAL CLK (TRUE)
	bit clk_c;																	//DIFFERENTIAL CLK (COMPLIMENT)

	bit REFRESH_START = LOW;													//FLAG FOR CHECKING REFRESH (ACTIVATE WHEN 1)
	bit [REFRESH_WIDTH-1 : 0] REFRESH_COUNTER;									//COUNTER TO ACTIVATE REFRESH STATE
	
	bit [2:0] i;																//LOOP VARIABLE FOR READ/WRITE STATE(BURST MODE ON)
	
/*-------------------------------------------------------------------------------
					  DECLARING BANKS FOR BANK GROUP 0 & 1
-------------------------------------------------------------------------------*/	
	logic [WORD_SIZE-1 : 0] bank0_0 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank0_1 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank0_2 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank0_3 [255 : 0][63 : 0];
	
	logic [WORD_SIZE-1 : 0] bank1_0 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank1_1 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank1_2 [255 : 0][63 : 0];
	logic [WORD_SIZE-1 : 0] bank1_3 [255 : 0][63 : 0];

	logic [WORD_SIZE-1 : 0] SENSE_AMP [63 : 0];								//SENSE AMPLIFIER ACTING AS ROW BUFFER TO WRITE IN BANK ROW

/*------------------------------------------------------------------------------*/

	State CURRENT_STATE, NEXT_STATE;											//State IS USER DEFINED DATA TYPE IN ddr4_pkg
	
	Bank_State CURRENT_BANK, NEXT_BANK;											//Bank_State IS USER DEFINED DATA TYPE IN ddr4_pkg

/*-------------------------------------------------------------------------------
								CLOCK GENERATION
-------------------------------------------------------------------------------*/
	always@(CKE)
	begin
		clk_t <= HIGH; clk_c <= LOW;											//INITIALIZE VALUES TO CLOCK_true & CLOCK_complement
		if(CKE == HIGH)															//TOGGLE ONLY WHEN CLOCK_ENABLE IS HIGH
			forever 
			begin 
				#5 clk_c <= ~clk_c;
				   clk_t <= ~clk_t;
			end
		else
			begin
				#5	clk_t <= clk_t; 
					clk_c <= clk_c;
			end
	end
/*-------------------------------------------------------------------------------
					ASSIGNING STATES BASED ON CLK_T
-------------------------------------------------------------------------------*/

	always_ff @(posedge clk_t or posedge clk_c)									
	begin
		if(RESET_n == LOW)														//CHECK FOR RESET HIGH AT EVERY CLOCK CYCLE AND MOVE TO RESET STATE
			CURRENT_STATE <= RESET;
		else
			begin
			CURRENT_STATE <= NEXT_STATE;										//IF NOT RESET MOVE TO NEXT STATE
			CURRENT_BANK <= NEXT_BANK;											//IF NOT RESET MOVE TO NEXT BANK
			end
	end	
/*-------------------------------------------------------------------------------
					  REFRESH COUNTER GENERATION
-------------------------------------------------------------------------------*/
	always @(posedge clk_t)
	begin
		if(REFRESH_COUNTER == REFRESH_PERIOD)									//WHEN REFRESH REACHES 32ms REFRESH STATE IS INITIATED
				REFRESH_START = HIGH;
		else
			REFRESH_COUNTER = REFRESH_COUNTER + 1'b1;							//INCREMENT COUNT UNTIL REFRESH COUNTER REACHES 32ms
	end
/*-------------------------------------------------------------------------------
					  		NAVIGATING FSM
-------------------------------------------------------------------------------*/
	always@(*)
	begin
	case(CURRENT_STATE)		
	RESET:	begin																//MOVING TO INITIALIZATION STATE AFTER RESET
				NEXT_STATE <= INITIALIZE;   
			end

	INITIALIZE:	begin															//MOVING TO IDLE STATE AFTER INITIALIZATION
				NEXT_STATE <= IDLE;
				end

	IDLE: 	begin																//CHECKING FOR REFRESH STATE ELSE MOVING TO ACTIVATE STATE
			if(REFRESH_START == HIGH)
					NEXT_STATE <= REFRESH;
			else if(ACT_n == LOW)
				NEXT_STATE <= ACTIVATE;
			end

	ACTIVATE: 	begin															//ACTIVATING BANK BASED BG AND BA FOR READ/WRITE OPERATIONS
					if(ACT_n == LOW)
					begin
					  	NEXT_BANK <= {BG,BA};
					  	case(NEXT_BANK)
						BANK0_0 : SENSE_AMP <= bank0_0[ROW_ADDRESS][63 : 0];
						BANK0_1 : SENSE_AMP <= bank0_1[ROW_ADDRESS][63 : 0];
						BANK0_2 : SENSE_AMP <= bank0_2[ROW_ADDRESS][63 : 0];
						BANK0_3 : SENSE_AMP <= bank0_3[ROW_ADDRESS][63 : 0];
						BANK1_0 : SENSE_AMP <= bank1_0[ROW_ADDRESS][63 : 0];
						BANK1_1 : SENSE_AMP <= bank1_1[ROW_ADDRESS][63 : 0];
						BANK1_2 : SENSE_AMP <= bank1_2[ROW_ADDRESS][63 : 0];
						BANK1_3 : SENSE_AMP <= bank1_3[ROW_ADDRESS][63 : 0];
						endcase	
					  	if(CS_n == LOW)											//ONLY WHEN CHIP_SELECT IS ON, WE CAN PERFORM READ/WRITE OPERATION ELSE PRE-CHARGE
					  	begin
						  	if(WE_n == LOW && AP == HIGH)						//WHEN WRITE MODE IS ON AND AUTO-PRECHARGE IS HIGH, NEXT STATE IS WRITE WITH AUTO-PRECHARGE
							NEXT_STATE <= WRITE_A;
							else if(WE_n == LOW && AP == LOW)					//WHEN WRITE MODE IS ON AND AUTO-PRECHARGE IS LOW, NEXT STATE IS ONLY WRITE STATE
							NEXT_STATE <= WRITE;
							else if(WE_n == HIGH && AP == HIGH)					//WHEN READ MODE IS ON AND AUTO-PRECHARGE IS HIGH, NEXT STATE IS READ STATE WITH AUTO-PRECHARGE
							NEXT_STATE <= READ_A;
							else												//WHEN READ MODE IS ON AND AUTO-PRECHARGE IS LOW, NEXT STATE IS ONLY READ STATE
							NEXT_STATE <= READ;
						end
						else if(CS_n == HIGH && AP == HIGH)						//WHEN CHIP_SELECT IS ON, AND AUTO-PRE IS HIGH, NEXT STATE IS PRE-CHARGE
							NEXT_STATE <= PRECHARGE;	
				  	end
			  	end
	WRITE:	begin																//WRITE DATA TO SENSE AMPLIFIER FROM TESTBENCH INPUT (DATAIN)
			if(CS_n == LOW)
				begin
				case(BURST_MODE)
				LOW :	SENSE_AMP[COL_ADDRESS] <= DATAIN;						//WRITING DATA TO SENSE AMPLIFIFER WHEN BURST_MODE IS OFF
				
				HIGH:   begin													//WRITING DATA TO SENSE AMNPLIFIER WHEN BURST_MODE IS ON
							for(i='0;i<BURST_LEN;i++)							//LOOPING STATEMENT TO LIMIT WRITE TILL BURST LENGTH
							begin
								@(posedge clk_t or posedge clk_c)
								SENSE_AMP[COL_ADDRESS + i] <= DATAIN;			//DATA WRITE TO SENSE AMPLIFIER DURING BURST MODE
							end
						end
				endcase
					if(WE_n == LOW && AP == HIGH)								//NAVIGATE TO DIFFERENT STATE AFTER WRITE OPERATION BASED ON READ/WRITE AND AUTO-PRE INPUTS
						NEXT_STATE <= WRITE_A;
					else if(WE_n == LOW && AP == LOW)
						NEXT_STATE <= WRITE;
					else if(WE_n == HIGH && AP == HIGH)
						NEXT_STATE <= READ_A;
					else
						NEXT_STATE <= READ;
				end
				else if(CS_n == HIGH && AP == HIGH)								//WHEN CHIP_SELECT IS OFF, AND AUTO-PRE IS HIGH, NEXT STATE IS PRE-CHARGE
					NEXT_STATE <= PRECHARGE;
			end
	
	WRITE_A: begin																//CHECK FOR BURST_MODE AND WRITE DATA TO SENSE AMPLIFIER WITH AUTO-PRECHARGE
			 case(BURST_MODE)
			 LOW :SENSE_AMP[COL_ADDRESS] <= DATAIN;
			 HIGH:begin
					for(i='0;i<BURST_LEN;i++)									//LOOPING STATEMENT TO LIMIT WRITE TILL BURST LENGTH
					begin
						@(posedge clk_t or posedge clk_c)
						SENSE_AMP[COL_ADDRESS + i] <= DATAIN;					//DATA WRITE TO SENSE AMPLIFIER DURING BURST MODE
					end
				  end
			 endcase	
				NEXT_STATE <= PRECHARGE;										//AUTO-PRECHARGE AFTER WRITE OPERATION
			 end
	
	READ:	begin																//READ OPERATION ACTIVE ONLY WHEN CHIP_SELECT IS ON ELSE PRE-CHARGE
			if(CS_n == LOW)
			begin
		     case(BURST_MODE)
			 LOW :DATAOUT <= SENSE_AMP[COL_ADDRESS];							//READ DATA FROM SENSE AMPLIFIER WHEN BURST_MODE IS OFF
			 HIGH:begin
					for(i='0;i<BURST_LEN;i++)									//LOOPING STATEMENT TO LIMIT READ TILL BURST LENGTH
					begin
						@(posedge clk_t or posedge clk_c)
						DATAOUT <= SENSE_AMP[COL_ADDRESS+i];					//READ DATA FROM SENSE AMPLIFIER WHEN BURST_MODE IS ON
					end
				  end
			 endcase		
				  	if(WE_n == LOW && AP == HIGH)								//NAVIGATE TO DIFFERENT STATE AFTER READ OPERATION BASED ON READ/WRITE AND AUTO-PRE INPUTS
					NEXT_STATE <= WRITE_A;
					else if(WE_n == LOW && AP == LOW)
					NEXT_STATE <= WRITE;
					else if(WE_n == HIGH && AP == HIGH)
					NEXT_STATE <= READ_A;
					else
					NEXT_STATE <= READ;
				end
				else if(CS_n == HIGH && AP == HIGH)								//WHEN CHIP_SELECT IS OFF, AND AUTO-PRE IS HIGH, NEXT STATE IS PRE-CHARGE
					NEXT_STATE <= PRECHARGE;
			end
	
	READ_A:	begin																//CHECK FOR BURST_MODE AND READ DATA FROM SENSE AMPLIFIER WITH AUTO-PRECHARGE
			case(BURST_MODE)
			 LOW :DATAOUT <= SENSE_AMP[COL_ADDRESS];
			 HIGH:begin
					for(i='0;i<BURST_LEN;i++)									//LOOPING STATEMENT TO LIMIT READ TILL BURST LENGTH
					begin
						@(posedge clk_t or posedge clk_c)
						DATAOUT <= SENSE_AMP[COL_ADDRESS+i];					//READ DATA FROM SENSE AMPLIFIER WHEN BURST_MODE IS ON
					end
				  end
			 endcase
			NEXT_STATE <= PRECHARGE;											//AUTO-PRECHARGE AFTER READ OPERATION
			end
			
	PRECHARGE:	begin															//WRITE DATA IN SENSE AMPLIFIER TO RESPECTIVE ROW/COLUMN IN CORRESPONDING BANK_GRP/BANK
				case(CURRENT_BANK)
				BANK0_0 : bank0_0[ROW_ADDRESS] <= SENSE_AMP;
				BANK0_1 : bank0_1[ROW_ADDRESS] <= SENSE_AMP;
				BANK0_2 : bank0_2[ROW_ADDRESS] <= SENSE_AMP;
				BANK0_3 : bank0_3[ROW_ADDRESS] <= SENSE_AMP;
				BANK1_0 : bank1_0[ROW_ADDRESS] <= SENSE_AMP;
				BANK1_1 : bank1_1[ROW_ADDRESS] <= SENSE_AMP;
				BANK1_2 : bank1_2[ROW_ADDRESS] <= SENSE_AMP;
				BANK1_3 : bank1_3[ROW_ADDRESS] <= SENSE_AMP;
				endcase	
				NEXT_STATE <= IDLE;												//MOVING TO IDLE STATE AFTER PRECHARGE
				end
	
	REFRESH: begin																//REFRESHES DATA INTO THE BANK AFTER 32ms
			 	repeat(5) 
			 		begin
			 		@(posedge clk_t)
			 			$display("REFRESH STATE in progress");
			 		end
		 		REFRESH_START <= LOW;											//RESET REFRESH_START FLAG TO LOW AFTER REFRESH OPERATION
	 			REFRESH_COUNTER <= '0;											//RESET REFRESH_COUNTER TO ALL 0's AFTER REFRESH OPERATION
			 	NEXT_STATE <= IDLE;
			 end
	endcase		
	end	
endmodule 
