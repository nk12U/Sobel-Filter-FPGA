module sobel_kernel(
   // Outputs
   gradient_x, gradient_y, magnitude,
   // Inputs
   pixel_00, pixel_01, pixel_02,
   pixel_10, pixel_11, pixel_12,
   pixel_20, pixel_21, pixel_22
);

   // 3x3 neighborhood input
   input [7:0] pixel_00, pixel_01, pixel_02;
   input [7:0] pixel_10, pixel_11, pixel_12;
   input [7:0] pixel_20, pixel_21, pixel_22;
   
   // gradient outputs
   output signed [11:0] gradient_x;  // horizontal gradient
   output signed [11:0] gradient_y;  // vertical gradient
   output [7:0] magnitude;           // edge magnitude
   
   // Sobel horizontal kernel: [-1, 0, 1; -2, 0, 2; -1, 0, 1]
   wire signed [11:0] gx_calc;
   assign gx_calc = (-1 * pixel_00) + (0 * pixel_01) + (1 * pixel_02) +
                    (-2 * pixel_10) + (0 * pixel_11) + (2 * pixel_12) +
                    (-1 * pixel_20) + (0 * pixel_21) + (1 * pixel_22);
   
   // Sobel vertical kernel: [1, 2, 1; 0, 0, 0; -1, -2, -1]
   wire signed [11:0] gy_calc;
   assign gy_calc = (1 * pixel_00) + (2 * pixel_01) + (1 * pixel_02) +
                    (0 * pixel_10) + (0 * pixel_11) + (0 * pixel_12) +
                    (-1 * pixel_20) + (-2 * pixel_21) + (-1 * pixel_22);
   
   // assign gradients
   assign gradient_x = gx_calc;
   assign gradient_y = gy_calc;
   
   // magnitude calculation: |gx| + |gy| (Manhattan distance)
   wire [11:0] abs_gx = (gx_calc[11] == 1'b1) ? -gx_calc : gx_calc;
   wire [11:0] abs_gy = (gy_calc[11] == 1'b1) ? -gy_calc : gy_calc;
   wire [12:0] magnitude_sum = abs_gx + abs_gy;
   
   // clamp to 8-bit (0-255)
   assign magnitude = (magnitude_sum > 255) ? 8'd255 : magnitude_sum[7:0];

endmodule