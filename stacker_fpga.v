module stacker_fpga(CLOCK_50, KEY, SW, GPIO_0, GPIO_1);
	input CLOCK_50;
	input [3:0] KEY;
	input [9:0] SW;
	output [35:0] GPIO_0;
	output [35:0] GPIO_1;
	
	stacker s(.clk(CLOCK_50),
				 .reset(KEY[1]),
				 .go(!KEY[0]),
				 .s_rate(SW[2:0]),
				 .s_blocks(SW[4:3]),
				 .column({GPIO_1[4], GPIO_0[2], GPIO_0[3], GPIO_1[1], GPIO_0[5], GPIO_1[2], GPIO_1[6], GPIO_1[7]}),
				 .row({GPIO_1[0], GPIO_1[5], GPIO_0[7], GPIO_1[3], GPIO_0[0], GPIO_0[6], GPIO_0[1], GPIO_0[4]})
				 );
endmodule
				 
module stacker(clk, reset, go, s_rate, s_blocks, column, row);
	input clk;
	input reset;
	input go;
	input [2:0] s_rate;
	input [1:0] s_blocks;
	output [7:0] column;
	output [7:0] row;
	
	wire [7:0] row_d_to_rc;
	wire [7:0] lrow_c_to_d;
	reg [7:0] lrow_main_to_c;
	wire [3:0] rowd_c_to_rc;
	wire [1:0] gstate_d_to_c;
	wire [27:0] rd1hz, rd2hz, rd4hz, rd8hz, rd10hz, rd16hz, rd24hz, rd32hz, rddriver;
	wire set_c_to_d;	
	reg en_rd_to_d;
	wire display_clk;
	wire driver_clk;
	wire game_state;
	wire [7:0] row0;
	wire [7:0] row1;
	wire [7:0] row2;
	wire [7:0] row3;
	wire [7:0] row4;
	wire [7:0] row5;
	wire [7:0] row6;
	wire [7:0] row7;
	wire shift;
	wire [4:0] current_state,next_state;
	wire [7:0] prev_row;
	reg rate; 
	
	rate_divider rddriver0(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd499),
	                .out(rddriver));

	rate_divider rd0(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd49999999),
	                .out(rd1hz));
						 
	rate_divider rd1(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd24999999),
	                .out(rd2hz));
						 
	rate_divider rd2(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd12499999),
	                .out(rd4hz));
						 
	rate_divider rd3(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd6249999),
	                .out(rd8hz));
						 
	rate_divider rd4(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd4999999),
	                .out(rd10hz));
						 
	rate_divider rd5(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd3124999),
	                .out(rd16hz));
	
	rate_divider rd6(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd2083332),
	                .out(rd24hz));
						 
	rate_divider rd7(.clk(clk), 
						 .reset(reset), 
						 .freq(27'd1562499),
	                .out(rd32hz));
	
	assign display_clk = (rd10hz == 0) ? 1 : 0;
	assign driver_clk = (rddriver == 0) ? 1 : 0;
						 
	always @(*) begin //select rate
		case (s_rate) 
			0: en_rd_to_d = (rd1hz == 0) ? 1 : 0;
			1: en_rd_to_d = (rd2hz == 0) ? 1 : 0;
			2: en_rd_to_d = (rd4hz == 0) ? 1 : 0;
			3: en_rd_to_d = (rd8hz == 0) ? 1 : 0;
			4: en_rd_to_d = (rd10hz == 0) ? 1 : 0;
			5: en_rd_to_d = (rd16hz == 0) ? 1 : 0;
			6: en_rd_to_d = (rd24hz == 0) ? 1 : 0;
			7: en_rd_to_d = (rd32hz == 0) ? 1 : 0;
		endcase
	end
	
	always @(*) begin //select blocks
		case (s_blocks)
			0: lrow_main_to_c = 8'b0000_0001;
			1: lrow_main_to_c = 8'b0000_0011;
			2: lrow_main_to_c = 8'b0000_0111;
			3: lrow_main_to_c = 8'b0000_1111;
		endcase
	end
	
	driver dr1(.row0(row0), 
				  .row1(row1), 
				  .row2(row2), 
				  .row3(row3), 
				  .row4(row4), 
				  .row5(row5), 
				  .row6(row6), 
				  .row7(row7), 
				  .clk(driver_clk), 
				  .reset(reset), 
				  .column_out(column), 
				  .row_out(row)
				  );
	
	row_controller r1(.clk(clk),
							.reset(reset),
							.display_clk(display_clk),
							.row_in(row_d_to_rc),
							.row_data_in(rowd_c_to_rc),
							.game_state(game_state),
							.row0(row0),
							.row1(row1),
							.row2(row2),
							.row3(row3),
							.row4(row4),
							.row5(row5),
							.row6(row6),
							.row7(row7)
							);
	
	control c1(.clk(clk),
			     .reset(reset),
			     .go(go), 
				  .s_blocks(lrow_main_to_c),
			     .set(set_c_to_d),
				  .row_data(rowd_c_to_rc),
	           .load_row(lrow_c_to_d)
			     );
	
	datapath d1(.clk(clk), 
					.reset(reset), 
					.en(en_rd_to_d),
					.set(set_c_to_d),
					.row_in(lrow_c_to_d),
					.row_out(row_d_to_rc),
					);
endmodule
	
module row_controller(clk, reset, display_clk, row_in, row_data_in, game_state, row0, row1, row2, row3, row4, row5, row6, row7);
	input clk;
	input reset;
	input display_clk;
	input [7:0] row_in; //from datapath
	input [3:0] row_data_in; //from control
	output reg [1:0] game_state;
	output reg [7:0] row0;
	output reg [7:0] row1;
	output reg [7:0] row2;
	output reg [7:0] row3;
	output reg [7:0] row4;
	output reg [7:0] row5;
	output reg [7:0] row6;
	output reg [7:0] row7;
	
	reg display_en;
	reg [5:0] shift_c;
	reg [49:0] d_row0 = 50'b1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_1111_0000_11; 
	reg [49:0] d_row1 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row2 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row3 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row4 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row5 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row6 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	reg [49:0] d_row7 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
	
	always @ (posedge display_clk, negedge reset) 
		if (!reset) begin
			d_row0 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00;  
			d_row1 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
			d_row2 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
			d_row3 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
			d_row4 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
			d_row5 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
			d_row6 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
			d_row7 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
			shift_c = 6'd50;
		end
		else if (display_en == 1) begin
			if (shift_c == 0) begin
				d_row0 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00;  
				d_row1 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
				d_row2 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
				d_row3 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
				d_row4 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
				d_row5 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
				d_row6 = 50'b1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_1000_00; 
				d_row7 = 50'b0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_0001_00;
				shift_c = 6'd50;
			end
			else begin
				d_row0 = d_row0 << 1; 
				d_row1 = d_row1 << 1; 
				d_row2 = d_row2 << 1; 
				d_row3 = d_row3 << 1; 
				d_row4 = d_row4 << 1; 
				d_row5 = d_row5 << 1; 
				d_row6 = d_row6 << 1; 
				d_row7 = d_row7 << 1;
				shift_c = shift_c - 1;
			end
		end

	always @ (posedge clk, negedge reset) begin
		if (!reset) begin
			row0 = row_in;
			row1 = 8'b0000_0000;
			row2 = 8'b0000_0000;
			row3 = 8'b0000_0000;
			row4 = 8'b0000_0000;
			row5 = 8'b0000_0000;
			row6 = 8'b0000_0000;
			row7 = 8'b0000_0000;
			display_en = 1'b0;
			game_state = 2'd0;
		end
		else begin
			if (row_in == 8'b0000_0000) begin
				row0 = d_row0[49:42];
				row1 = 8'b1110_0111;
				row2 = 8'b0111_1110;
				row3 = 8'b0011_1100;
				row4 = 8'b0011_1100;
				row5 = 8'b0111_1110;
				row6 = 8'b1110_0111;
				row7 = 8'b1100_0011;
				display_en = 1'b1;
				game_state = 2'd2;
			end
			else begin
				case(row_data_in) 
					0: row0 = row_in;
					1: row1 = row_in;
					2: row2 = row_in;
					3: row3 = row_in;
					4: row4 = row_in;
					5: row5 = row_in;
					6: row6 = row_in;
					7: row7 = row_in;
					8: begin 
						row0 = 8'b0000_0000;
						row1 = 8'b0000_0001;
						row2 = 8'b0000_0011;
						row3 = 8'b1100_0111;
						row4 = 8'b1110_1110;
						row5 = 8'b0111_1100;
						row6 = 8'b0011_1000;
						row7 = 8'b0001_0000;
						display_en = 1'b1;
						game_state = 2'd1;
					   end
				endcase
			end
		end
	end
endmodule

module control(clk, reset, go, s_blocks, set, row_data, load_row);
	input clk; //from topmodule
	input reset; //from topmodule
	input go; //from topmodule
	input [7:0] s_blocks;
	output reg set; //to datapath
	output reg [3:0] row_data; //to row_controller
	output reg [7:0] load_row; //to datapath

	reg [4:0] current_state;
	reg [4:0] next_state;

	localparam 
		S_ROW0_LOAD = 5'd0,
		S_ROW0_WAIT = 5'd1,
		S_ROW0_SET  = 5'd2,
		S_ROW1_LOAD = 5'd3,
		S_ROW1_WAIT = 5'd4,
		S_ROW1_SET  = 5'd5,
		S_ROW2_LOAD = 5'd6,
		S_ROW2_WAIT = 5'd7,
		S_ROW2_SET  = 5'd8,
		S_ROW3_LOAD = 5'd9,
		S_ROW3_WAIT = 5'd10,
		S_ROW3_SET  = 5'd11,
		S_ROW4_LOAD = 5'd12,
		S_ROW4_WAIT = 5'd13,
		S_ROW4_SET  = 5'd14,
		S_ROW5_LOAD = 5'd15,
		S_ROW5_WAIT = 5'd16,
		S_ROW5_SET  = 5'd17,
		S_ROW6_LOAD = 5'd18,
		S_ROW6_WAIT = 5'd19,
		S_ROW6_SET  = 5'd20,
		S_ROW7_LOAD = 5'd21,
		S_ROW7_WAIT = 5'd22,
		S_ROW7_SET 	= 5'd23,
		S_WON = 5'd24;

	always @(*) begin: state_table
		case (current_state)
			S_ROW0_LOAD : next_state = S_ROW0_WAIT;
			S_ROW0_WAIT : next_state = go ? S_ROW0_SET : S_ROW0_WAIT;
			S_ROW0_SET  : next_state = go ? S_ROW0_SET : S_ROW1_LOAD;
			S_ROW1_LOAD : next_state = S_ROW1_WAIT;
			S_ROW1_WAIT : next_state = go ? S_ROW1_SET : S_ROW1_WAIT;
			S_ROW1_SET  : next_state = go ? S_ROW1_SET : S_ROW2_LOAD;
			S_ROW2_LOAD : next_state = S_ROW2_WAIT;
			S_ROW2_WAIT : next_state = go ? S_ROW2_SET : S_ROW2_WAIT;
			S_ROW2_SET  : next_state = go ? S_ROW2_SET : S_ROW3_LOAD;
			S_ROW3_LOAD : next_state = S_ROW3_WAIT;
			S_ROW3_WAIT : next_state = go ? S_ROW3_SET : S_ROW3_WAIT;
			S_ROW3_SET  : next_state = go ? S_ROW3_SET : S_ROW4_LOAD;
			S_ROW4_LOAD : next_state = S_ROW4_WAIT;
			S_ROW4_WAIT : next_state = go ? S_ROW4_SET : S_ROW4_WAIT;
			S_ROW4_SET  : next_state = go ? S_ROW4_SET : S_ROW5_LOAD;
			S_ROW5_LOAD : next_state = S_ROW5_WAIT;
			S_ROW5_WAIT : next_state = go ? S_ROW5_SET : S_ROW5_WAIT;
			S_ROW5_SET  : next_state = go ? S_ROW5_SET : S_ROW6_LOAD;
			S_ROW6_LOAD : next_state = S_ROW6_WAIT;
			S_ROW6_WAIT : next_state = go ? S_ROW6_SET : S_ROW6_WAIT;
			S_ROW6_SET  : next_state = go ? S_ROW6_SET : S_ROW7_LOAD;
			S_ROW7_LOAD : next_state = S_ROW7_WAIT;
			S_ROW7_WAIT : next_state = go ? S_ROW7_SET : S_ROW7_WAIT;
			S_ROW7_SET 	: next_state = go ? S_ROW7_SET : S_WON;
			S_WON 		: next_state = S_WON;
			default : next_state = S_ROW0_WAIT;
		endcase
	end
	
	always @(*) begin: enable_signals
		set = 1'b0;
		load_row = s_blocks;
		//row_data <= 4'd0;
		case (current_state)
			S_ROW0_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd0;
							end
			S_ROW0_WAIT : begin
							set = 1'b0;
							row_data = 4'd0;	
							end
			S_ROW0_SET :  begin
							set = 1'b1;
							row_data = 4'd0;
							end
			S_ROW1_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd1;
							end
			S_ROW1_WAIT : begin 
							set = 1'b0;
							row_data = 4'd1;
							end
			S_ROW1_SET :  begin
							set = 1'b1;
							row_data = 4'd1;
							end
			S_ROW2_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd2;
							end
			S_ROW2_WAIT : begin
							set = 1'b0;
							row_data = 4'd2;
							end
			S_ROW2_SET :  begin
							set = 1'b1;
							row_data = 4'd2;
							end
			S_ROW3_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd3;
							end
			S_ROW3_WAIT : begin
							set = 1'b0;
							row_data = 4'd3;
							end
		   S_ROW3_SET :  begin
							set = 1'b1;
							row_data = 4'd3;
							end
			S_ROW4_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd4;
							end
			S_ROW4_WAIT : begin
							set = 1'b0;
							row_data = 4'd4;
							end
			S_ROW4_SET :  begin
							set = 1'b1;
							row_data = 4'd4;
							end
			S_ROW5_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd5;
							end
			S_ROW5_WAIT : begin
							set = 1'b0;
							row_data = 4'd5;
							end
			S_ROW5_SET :  begin
							set = 1'b1;
							row_data = 4'd5;
							end
			S_ROW6_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd6;
							end
			S_ROW6_WAIT : begin
							set = 1'b0;
							row_data = 4'd6;
							end
			S_ROW6_SET :  begin
							set = 1'b1;
							row_data = 4'd6;
							end
			S_ROW7_LOAD : 	begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd7;
							end
			S_ROW7_WAIT : begin
							set = 1'b0;
							row_data = 4'd7;
							end
			S_ROW7_SET  : begin
							set = 1'b1;
							row_data = 4'd7;
							end
			S_WON 		:  begin
							set = 1'b1;
							load_row = s_blocks;
							row_data = 4'd8;
							end
		endcase
	end

	always @ (posedge clk, negedge reset) begin: state_FFs
        if (!reset)
           	current_state <= S_ROW0_LOAD;
        else begin
        		current_state <= next_state;
        end
    end 
endmodule

module datapath(clk, reset, en, set, row_in, row_out);
	input clk; //from topmodule
	input reset; //from topmodule
	input en; //from topmodule
	input set; //from control
	input [7:0] row_in; //from control
	output reg [7:0] row_out; //to row_controller

	reg [7:0] prev_row;
	reg shift; //0: left, 1: right

	always @ (posedge clk or negedge reset) 
		if (!reset) begin
			row_out <= row_in;
			shift <= 0;
		end 
		else if (set == 0) begin
			if (en == 1) 
				case (shift) //shifting blocks or not
					0: begin
						if (row_out[7] == 1) begin
							row_out <= row_out >> 1;
							shift <= 1;
						end
						else begin
							row_out <= row_out << 1;
						end
						end
					1:	begin
						if (row_out[0] == 1) begin
							row_out <= row_out << 1;
							shift <= 0;
						end
						else begin
							row_out <= row_out >> 1;
						end
						end
				default: row_out <= row_in;
				endcase
		end
		else begin
			row_out <= row_out & prev_row;
		end
		
	always @ (posedge set or negedge reset) 
		if (!reset) begin
			prev_row = 8'b1111_1111;
		end
		else begin
			prev_row <= row_out & prev_row;
		end
endmodule

module rate_divider(clk, reset, freq, out);
   input clk;
	input reset;
	input [27:0] freq;
	output reg [27:0] out;

	always @(posedge clk, negedge reset)
	begin
		if (!reset)
			out = freq;
		else begin
			if (out == 1'b0)
				out <= freq; 
			else
				out <= out - 1'b1;
		end  
	end
endmodule	 

module driver(row0, row1, row2, row3, row4, row5, row6, row7, clk, reset, column_out, row_out);
	input [7:0] row0; 
	input [7:0] row1;
	input [7:0] row2; 
	input [7:0] row3;
	input [7:0] row4; 
	input [7:0] row5;
	input [7:0] row6; 
	input [7:0] row7;
	input clk;
	input reset;
	output reg [7:0] column_out;
	output reg [7:0] row_out;

	reg [7:0] r_counter = 0;
	reg [7:0] c_counter = 8'b0000_0001;

	always@ (posedge clk) begin
		case(r_counter) 
			0: 
				begin
				column_out <= ~(row0 & c_counter);
				row_out <= 8'b0000_0001;
				end
			1: 
				begin
				column_out <= ~(row1 & c_counter);
				row_out <= 8'b0000_0010;
				end
			2: 
				begin
				column_out <= ~(row2 & c_counter);
				row_out <= 8'b0000_0100;
				end
			3: 
				begin
				column_out <= ~(row3 & c_counter);
				row_out <= 8'b0000_1000;
				end
			4: 
				begin
				column_out <= ~(row4 & c_counter);
				row_out <= 8'b0001_0000;
				end
			5: 
				begin
				column_out <= ~(row5 & c_counter);
				row_out <= 8'b0010_0000;
				end
			6: 
				begin
				column_out <= ~(row6 & c_counter);
				row_out <= 8'b0100_0000;
				end
			7: 
				begin
				column_out <= ~(row7 & c_counter);
				row_out <= 8'b1000_0000;
				end
		endcase

		if (reset != 0)	begin								//no reset signal
			if (c_counter == 8'b1000_0000) begin			//if column counter reaches "last" column
				c_counter <= 8'b0000_0001;						//start again at beginning of column and increment row
				if (r_counter == 7) 
				begin							//if row reaches max value
						r_counter <= 0;									//row set back to 0
				end
				else begin 
					r_counter <= r_counter + 1'b1;						//otherwise just increment row
				end
			end
			else begin
				c_counter <= c_counter << 1;				//otherwise just shift column left
			end
		end
		else begin
			r_counter <= 0;
			c_counter <= 8'b0000_0001;
		end
	end
endmodule
