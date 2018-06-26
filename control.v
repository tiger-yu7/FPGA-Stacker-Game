module row_controller(
	input clk;
	input reset;
	input [7:0] row_in; //from datapath
	input [3:0] row_data_in; //from control
	output reg [7:0] row0;
	output reg [7:0] row1;
	output reg [7:0] row2;
	output reg [7:0] row3;
	output reg [7:0] row4;
	output reg [7:0] row5;
	output reg [7:0] row6;
	output reg [7:0] row7;
	)

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
				8: row7 = 8'b1111_1111;
				9: row6 = 8'b1111_1111;
			endcase
		end
	end
endmodule

module control(
	input clk; //from topmodule
	input reset; //from topmodule
	input go; //from topmodule
	input game_state; // from datapath
	output reg set; //to datapath
	output reg [3:0] row_data; //to row_controller
	output reg [7:0] load_row; //to control
	);

	reg [4:0] current_state;
	reg [4:0] next_state;

	localparam 
		S_ROW0_LOAD = 5'd0;
		S_ROW0_WAIT = 5'd1;
		S_ROW1_LOAD = 5'd2;
		S_ROW1_WAIT = 5'd3;
		S_ROW2_LOAD = 5'd4;
		S_ROW2_WAIT = 5'd5;
		S_ROW3_LOAD = 5'd6;
		S_ROW3_WAIT = 5'd7;
		S_ROW4_LOAD = 5'd8;
		S_ROW4_WAIT = 5'd9;
		S_ROW5_LOAD = 5'd10;
		S_ROW5_WAIT = 5'd11;
		S_ROW6_LOAD = 5'd12;
		S_ROW6_WAIT = 5'd13;
		S_ROW7_LOAD = 5'd14;
		S_ROW7_WAIT = 5'd15;
		S_WON = 5'd16
		S_LOST = 5'd17

	always @(*) begin: state_table
		case (current_state)
			S_ROW0_LOAD : next_state = S_ROW0_WAIT;
			S_ROW0_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW1_LOAD : next_state = S_ROW0_WAIT;
			S_ROW1_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW2_LOAD : next_state = S_ROW0_WAIT;
			S_ROW2_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW3_LOAD : next_state = S_ROW0_WAIT;
			S_ROW3_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW4_LOAD : next_state = S_ROW0_WAIT;
			S_ROW4_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW5_LOAD : next_state = S_ROW0_WAIT;
			S_ROW5_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW6_LOAD : next_state = S_ROW0_WAIT;
			S_ROW6_WAIT : next_state = go ? S_ROW1_LOAD : S_ROW0_WAIT;
			S_ROW7_LOAD : next_state = S_ROW0_WAIT;
			S_ROW7_WAIT : next_state = go ? S_WON : S_ROW0_WAIT;
			default : next_state = S_ROW0_WAIT;
		endcase
	end

	always @(*) begin: enable_signals
		case (current_state)
			S_ROW0_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd0;
							end
			S_ROW0_WAIT : set <= 1'b0;
			S_ROW1_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd1;
							end
			S_ROW1_WAIT : set <= 1'b0;
			S_ROW2_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd2;
							end
			S_ROW2_WAIT : set <= 1'b0;
			S_ROW3_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd3;
							end
			S_ROW3_WAIT : set <= 1'b0;
			S_ROW4_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd4;
							end
			S_ROW4_WAIT : set <= 1'b0;
			S_ROW5_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd5;
							end
			S_ROW5_WAIT : set <= 1'b0;
			S_ROW6_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd6;
							end
			S_ROW6_WAIT : set <= 1'b0;
			S_ROW7_LOAD : 	begin
							set <= 1'b1;
							load_row <= 8'b0000_0111;
							row_data <= 4'd7;
							end
			S_ROW7_WAIT : set <= 1'b0;
			S_WON : row_data <= 4'd8;
			S_LOST : row_data <= 4'd9;

	always @ (posedge clk, negedge reset) begin: state_FFs
        if (!reset)
           	current_state <= S_ROW0_LOAD;
        else begin
        	if (game_state == 1'b1) 
        		current_state <= S_LOST;
        	else begin
        		current_state <= next_state;
        	end
        end
    end 
endmodule

module datapath(
	input clk; //from topmodule
	input reset; //from topmodule
	input en; //from topmodule
	input set; //from control
	input [7:0] row_in; //from control
	output reg [7:0] row_out; //to row_controller
	output reg game_state; //to control
	);

	reg [7:0] prev_row;
	reg shift; //0: left, 1: right

	always @ (posedge en, negedge reset, posedge set,) begin
		if (!reset) begin
			row_out = row_in;
			prev_row = 8'b1111_1111;
			shift = 0;
			game_state = 0;
		end 
		else begin
			if (!set) 
				case (shift) //shifting blocks or not
					0: 	begin
						if (row_out[7] == 1) begin
							row_out = row_out >> 1;
							shift = 1;
						end
						else begin
							row_out = row_out << 1;
						end
					1:	begin
						if (row_out[0] == 1) begin
							row_out = row_out << 1;
							shift = 0;
						end
						else begin
							row_out = row_out >> 1;
						end
				default: row_out = row_in;
				endcase
			end
			else begin
				row_out = row_out & prev_row;
				if ((row_out & prev_row) == 8'b0) begin
					game_state = 1;
				end
				else begin
					prev_row = row_out;
				end
			end
		end
	end
endmodule

	
