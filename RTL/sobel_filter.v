module sobel_filter(
   // Outputs
   rcv_req, pixel_rgb_out, snd_ack,
   // Inputs
   clk, xrst, pixel_rgb_in, rcv_ack, snd_req
);

   // clock, reset
   input clk;
   input xrst;

   // receive port (MASTER)
   input [23:0] pixel_rgb_in;  // RGB 24-bit input
   output rcv_req;
   input rcv_ack;

   // send port (SLAVE)
   output [23:0] pixel_rgb_out;  // RGB 24-bit output
   input snd_req;
   output snd_ack;

   // extract RGB channels
   wire [7:0] pixel_r_in = pixel_rgb_in[23:16];
   wire [7:0] pixel_g_in = pixel_rgb_in[15:8];
   wire [7:0] pixel_b_in = pixel_rgb_in[7:0];

   //////////////////////////////////////////////////////////
   // stage 0 (line buffers for each channel)
   //////////////////////////////////////////////////////////
   reg enable_reg;
   
   // pixel position tracking for boundary detection
   reg [7:0] row_count;
   reg [6:0] col_count;
   
   parameter WIDTH = 128;
   parameter HEIGHT = 128;
   
   // ADDED: Counter logic for current pixel position
   always @(posedge clk or negedge xrst) begin
       if (xrst == 1'b0) begin
           row_count <= 8'd0;
           col_count <= 7'd0;
       end else if (enable_reg) begin
           if (col_count == WIDTH - 1) begin
               col_count <= 7'd0;
               if (row_count == HEIGHT - 1) begin
                   row_count <= 8'd0; // Reset for next frame
               end else begin
                   row_count <= row_count + 1'b1;
               end
           end else begin
               col_count <= col_count + 1'b1;
           end
       end
   end

   // line buffers for R, G, B channels
   wire [7:0] r_pixel_00, r_pixel_01, r_pixel_02;
   wire [7:0] r_pixel_10, r_pixel_11, r_pixel_12;
   wire [7:0] r_pixel_20, r_pixel_21, r_pixel_22;
   
   wire [7:0] g_pixel_00, g_pixel_01, g_pixel_02;
   wire [7:0] g_pixel_10, g_pixel_11, g_pixel_12;
   wire [7:0] g_pixel_20, g_pixel_21, g_pixel_22;
   
   wire [7:0] b_pixel_00, b_pixel_01, b_pixel_02;
   wire [7:0] b_pixel_10, b_pixel_11, b_pixel_12;
   wire [7:0] b_pixel_20, b_pixel_21, b_pixel_22;

   line_buffer line_buf_r(
      .pixel_00(r_pixel_00), .pixel_01(r_pixel_01), .pixel_02(r_pixel_02),
      .pixel_10(r_pixel_10), .pixel_11(r_pixel_11), .pixel_12(r_pixel_12),
      .pixel_20(r_pixel_20), .pixel_21(r_pixel_21), .pixel_22(r_pixel_22),
      .pixel_in(pixel_r_in), .enable(enable_reg), .clk(clk), .xrst(xrst),
      .row_count(row_count), .col_count(col_count)
   );

   line_buffer line_buf_g(
      .pixel_00(g_pixel_00), .pixel_01(g_pixel_01), .pixel_02(g_pixel_02),
      .pixel_10(g_pixel_10), .pixel_11(g_pixel_11), .pixel_12(g_pixel_12),
      .pixel_20(g_pixel_20), .pixel_21(g_pixel_21), .pixel_22(g_pixel_22),
      .pixel_in(pixel_g_in), .enable(enable_reg), .clk(clk), .xrst(xrst),
      .row_count(row_count), .col_count(col_count)
   );

   line_buffer line_buf_b(
      .pixel_00(b_pixel_00), .pixel_01(b_pixel_01), .pixel_02(b_pixel_02),
      .pixel_10(b_pixel_10), .pixel_11(b_pixel_11), .pixel_12(b_pixel_12),
      .pixel_20(b_pixel_20), .pixel_21(b_pixel_21), .pixel_22(b_pixel_22),
      .pixel_in(pixel_b_in), .enable(enable_reg), .clk(clk), .xrst(xrst),
      .row_count(row_count), .col_count(col_count)
   );

   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
         enable_reg <= 1'b0;
      else
         enable_reg <= rcv_ack;
   end

   //////////////////////////////////////////////////////////
   // stage 1 (Sobel kernel computation)
   //////////////////////////////////////////////////////////
   reg s1_ack_reg;
   
   wire [7:0] r_magnitude, g_magnitude, b_magnitude;
   wire signed [11:0] r_gx, r_gy, g_gx, g_gy, b_gx, b_gy;

   sobel_kernel sobel_r(
      .gradient_x(r_gx), .gradient_y(r_gy), .magnitude(r_magnitude),
      .pixel_00(r_pixel_00), .pixel_01(r_pixel_01), .pixel_02(r_pixel_02),
      .pixel_10(r_pixel_10), .pixel_11(r_pixel_11), .pixel_12(r_pixel_12),
      .pixel_20(r_pixel_20), .pixel_21(r_pixel_21), .pixel_22(r_pixel_22)
   );

   sobel_kernel sobel_g(
      .gradient_x(g_gx), .gradient_y(g_gy), .magnitude(g_magnitude),
      .pixel_00(g_pixel_00), .pixel_01(g_pixel_01), .pixel_02(g_pixel_02),
      .pixel_10(g_pixel_10), .pixel_11(g_pixel_11), .pixel_12(g_pixel_12),
      .pixel_20(g_pixel_20), .pixel_21(g_pixel_21), .pixel_22(g_pixel_22)
   );

   sobel_kernel sobel_b(
      .gradient_x(b_gx), .gradient_y(b_gy), .magnitude(b_magnitude),
      .pixel_00(b_pixel_00), .pixel_01(b_pixel_01), .pixel_02(b_pixel_02),
      .pixel_10(b_pixel_10), .pixel_11(b_pixel_11), .pixel_12(b_pixel_12),
      .pixel_20(b_pixel_20), .pixel_21(b_pixel_21), .pixel_22(b_pixel_22)
   );

   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
         s1_ack_reg <= 1'b0;
      else
         s1_ack_reg <= enable_reg;
   end

   //////////////////////////////////////////////////////////
   // stage 2 (output registration)
   //////////////////////////////////////////////////////////
   reg [7:0] s2_r_reg, s2_g_reg, s2_b_reg;
   reg s2_ack_reg;

   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0) begin
         s2_r_reg <= 8'd0;
         s2_g_reg <= 8'd0;
         s2_b_reg <= 8'd0;
      end
      else begin
         s2_r_reg <= r_magnitude;
         s2_g_reg <= g_magnitude;
         s2_b_reg <= b_magnitude;
      end
   end

   always @(posedge clk or negedge xrst) begin
      if (xrst == 1'b0)
         s2_ack_reg <= 1'b0;
      else
         s2_ack_reg <= s1_ack_reg;
   end

   //////////////////////////////////////////////////////////
   // output assignment
   //////////////////////////////////////////////////////////
   assign pixel_rgb_out = {s2_r_reg, s2_g_reg, s2_b_reg};
   assign snd_ack = s2_ack_reg;
   assign rcv_req = snd_req;

endmodule