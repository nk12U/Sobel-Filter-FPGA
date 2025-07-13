`timescale 1ps / 1ps

module test_top();

   parameter CLK = 1000000/10; // 10MHz

   parameter PIXEL_NUM = 128 * 128;

   reg [7:0]  r_imem [0:PIXEL_NUM-1];
   reg [7:0]  g_imem [0:PIXEL_NUM-1]; 
   reg [7:0]  b_imem [0:PIXEL_NUM-1];
   
   reg [7:0]  r_omem [0:PIXEL_NUM-1];
   reg [7:0]  g_omem [0:PIXEL_NUM-1];
   reg [7:0]  b_omem [0:PIXEL_NUM-1];

   // receive port (SLAVE)
   reg [23:0] pixel_in;   // RGB 24-bit input
   wire       rcv_req;
   reg        rcv_ack;

   // send port (MASTER)
   wire [23:0] pixel_out; // RGB 24-bit output
   reg         snd_req;
   wire        snd_ack;

   // clock, reset
   reg         clk;
   reg         xrst;

   time start_time;
   integer i;
   time input_end;
   time filter_end;
   time output_end;

   // clock generation
   always begin
      clk = 1'b1;
      #(CLK/2);
      clk = 1'b0;
      #(CLK/2);
   end

   // test scenario
   initial begin

      // reset
      #(CLK/2);
      xrst = 1'b0;
      read_ppm_image;
      #(CLK);
      xrst = 1'b1;
      rcv_ack = 1'b0;
      snd_req = 1'b0;

      start_time = $time;

      // data input
      while (rcv_req == 1'b0) #(CLK);
      #(CLK);
      for (i = 0; i < PIXEL_NUM; i = i + 1) begin
         rcv_ack = 1'b1;
         pixel_in = {r_imem[i], g_imem[i], b_imem[i]};  // pack RGB
         #(CLK);
      end
      rcv_ack = 1'b0;

      input_end = $time;
      
      // data output
      snd_req = 1'b1;
      while (snd_ack == 1'b0) #(CLK);
      snd_req = 1'b0;
      filter_end = $time;
      for (i = 0; i < PIXEL_NUM; i = i + 1) begin
         r_omem[i] = pixel_out[23:16];  // unpack RGB
         g_omem[i] = pixel_out[15:8];
         b_omem[i] = pixel_out[7:0];
         #(CLK);
      end

      output_end = $time;
      $display("Simulation time: %d ns", ($time-start_time)/1000);

      #(CLK*10);
      
      save_ppm_image;
      $finish;
   end

   // module instantiation
   top top0(// Outputs
        .rcv_req        (rcv_req),
        .pixel_out      (pixel_out[23:0]),
        .snd_ack        (snd_ack),
        // Inputs
        .pixel_in       (pixel_in[23:0]),
        .rcv_ack        (rcv_ack),
        .snd_req        (snd_req),
        .clk            (clk),
        .xrst           (xrst));

   task read_ppm_image;
      reg [7:0] r_val, g_val, b_val;
      integer fd;
      integer i;
      integer c;
      reg [127:0] str;
      begin
         fd = $fopen("touji.ppm", "r");
         // skip header lines (P3, dimensions, maxval)
         c = $fgets(str, fd);  // P3
         c = $fgets(str, fd);  // 128 128  
         c = $fgets(str, fd);  // 255
         // read RGB pixels
         for (i = 0; i < PIXEL_NUM; i = i + 1) begin
            c = $fscanf(fd, "%d %d %d", r_val, g_val, b_val);
            r_imem[i] = r_val;
            g_imem[i] = g_val;
            b_imem[i] = b_val;
         end
         $fclose(fd);
      end
   endtask

   task save_ppm_image;
      integer fd;
      integer i;
      begin
         fd = $fopen("output.ppm", "w");
         // write headers
         $fdisplay(fd, "P3");
         $fdisplay(fd, "128 128");
         $fdisplay(fd, "255");
         // write RGB pixels
         for (i = 0; i < PIXEL_NUM; i = i + 1) begin
            $fdisplay(fd, "%d %d %d", r_omem[i], g_omem[i], b_omem[i]);
         end
         $fclose(fd);
      end
   endtask

endmodule