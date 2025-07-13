module top(
   // Outputs
   rcv_req, pixel_out, snd_ack,
   // Inputs
   clk, xrst, pixel_in, rcv_ack, snd_req
   );

   // clock, reset
   input 	clk;
   input 	xrst;

   // receive port (MASTER)
   input [23:0] pixel_in;    // RGB 24-bit input
   output       rcv_req;
   input        rcv_ack;

   // send port (SLAVE)
   output [23:0] pixel_out;  // RGB 24-bit output
   input 	snd_req;
   output 	snd_ack;

   // wire (buf0 <-> sobel_filter)
   wire [23:0] buf0_sobel_pixel;
   wire        buf0_sobel_ack;
   wire        sobel_buf0_req;

   // wire (sobel_filter <-> buf1)
   wire [23:0] sobel_buf1_pixel;
   wire        sobel_buf1_ack;
   wire        buf1_sobel_req;

   framebuf_rgb buf0(
       // Outputs
		 .rcv_req	(rcv_req),
		 .pixel_out	(buf0_sobel_pixel[23:0]),
		 .snd_ack	(buf0_sobel_ack),
		 // Inputs
		 .pixel_in	(pixel_in[23:0]),
		 .rcv_ack	(rcv_ack),
		 .snd_req	(sobel_buf0_req),
		 .clk		(clk),
		 .xrst		(xrst));

   sobel_filter sobel0(
       // Outputs
		 .rcv_req	(sobel_buf0_req),
		 .pixel_rgb_out	(sobel_buf1_pixel[23:0]),
		 .snd_ack	(sobel_buf1_ack),
		 // Inputs
		 .pixel_rgb_in	(buf0_sobel_pixel[23:0]),
		 .rcv_ack	(buf0_sobel_ack),
		 .snd_req	(buf1_sobel_req),
		 .clk		(clk),
		 .xrst		(xrst));

   framebuf_rgb buf1(
       // Outputs
		 .rcv_req	(buf1_sobel_req),
		 .pixel_out	(pixel_out[23:0]),
		 .snd_ack	(snd_ack),
		 // Inputs
		 .pixel_in	(sobel_buf1_pixel[23:0]),
		 .rcv_ack	(sobel_buf1_ack),
		 .snd_req	(snd_req),
		 .clk		(clk),
		 .xrst		(xrst));

endmodule
