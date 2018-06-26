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

	always(@ posedge clk) 
	begin 
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
				if (r_counter = 7) begin							//if row reaches max value
						r_counter <= 0;									//row set back to 0
				end
				else begin 
					r_counter <= r_counter + 1;						//otherwise just increment row
				end
			end
			else begin
				c_counter <= c_counter << 1;				//otherwise just shift column left
			end
		end
		else begin
			row_counter <= 0;
			c_counter <= 8'b0000_0001;
		end
	end



endmodule