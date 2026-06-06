module led_blink(
	input clock,
	output reg led
);
	parameter counter_max = 6250000;

	reg [31:0] counter;

	always @ (posedge clock)
	begin
		if (counter == counter_max - 1)
		begin
			led <= ~led;
			counter <= 0;
		end
		else
		begin
			counter <= counter + 1;
		end
	end
endmodule
