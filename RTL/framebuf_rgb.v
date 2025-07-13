module framebuf_rgb(
   // Outputs
   rcv_req, pixel_out, snd_ack,
   // Inputs
   clk, xrst, pixel_in, rcv_ack, snd_req
   );

   // parameter
   parameter PIXEL_NUM = 128 * 128;

   // clock, reset
   input 	clk;
   input 	xrst;

   // receive port (MASTER)
   input [23:0] pixel_in;  // RGB 24-bit input
   output       rcv_req;
   input        rcv_ack;

   // send port (SLAVE)
   output [23:0] pixel_out;  // RGB 24-bit output
   input 	snd_req;
   output 	snd_ack;

   // state machine
   reg [1:0]   state_reg;
   parameter   ST_WAIT_RCV_ACK = 2'd0;
   parameter   ST_RCV_DATA     = 2'd1;
   parameter   ST_WAIT_SND_REQ = 2'd2;
   parameter   ST_SND_DATA     = 2'd3;

   // memory (RGB channels)
   reg  [23:0]  mem[0:PIXEL_NUM-1];
   reg  [14:0]  mem_addr;
   wire         mem_we;
   wire [23:0]  mem_din;
   reg  [23:0]  mem_dout;

   // state machine
   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
	      state_reg <= ST_WAIT_RCV_ACK;
      else
        case (state_reg)
          ST_WAIT_RCV_ACK:
            if (rcv_ack == 1'b1)
	            state_reg <= ST_RCV_DATA;
          ST_RCV_DATA:
	          if (mem_addr == PIXEL_NUM-1)
	            state_reg <= ST_WAIT_SND_REQ;
          ST_WAIT_SND_REQ:
            if (snd_req == 1'b1)
	            state_reg <= ST_SND_DATA;
          ST_SND_DATA:
	          if (mem_addr == PIXEL_NUM-1)
	            state_reg <= ST_WAIT_RCV_ACK;
        endcase
   end

   // memory address
   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
         mem_addr <= 15'd0;
      else
        case (state_reg)
          ST_RCV_DATA:
            mem_addr <= mem_addr + 1'b1;
          ST_SND_DATA:
            mem_addr <= mem_addr + 1'b1;
          default:
            mem_addr <= 15'd0;
        endcase
   end

   // memory control
   assign mem_we = (state_reg == ST_RCV_DATA);
   assign mem_din = pixel_in;

   // memory write
   always @(posedge clk) begin
      if (mem_we)
         mem[mem_addr] <= mem_din;
   end

   // memory read
   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
         mem_dout <= 24'd0;
      else
         mem_dout <= mem[mem_addr];
   end

   // output assignment
   assign rcv_req = (state_reg == ST_WAIT_RCV_ACK) ? 1'b1 : 1'b0;
   assign snd_ack = (state_reg == ST_SND_DATA) ? 1'b1 : 1'b0;
   assign pixel_out = mem_dout;

endmodule