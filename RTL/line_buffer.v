module line_buffer(
    // Outputs
    pixel_00, pixel_01, pixel_02,
    pixel_10, pixel_11, pixel_12,
    pixel_20, pixel_21, pixel_22,
    // Inputs
    clk, xrst, pixel_in, enable, row_count, col_count
);

    // clock, reset
    input clk;
    input xrst;

    // pixel input
    input [7:0] pixel_in;
    input enable;
    input [7:0] row_count;
    input [6:0] col_count;

    // 3x3 neighborhood output
    output [7:0] pixel_00, pixel_01, pixel_02;
    output [7:0] pixel_10, pixel_11, pixel_12;
    output [7:0] pixel_20, pixel_21, pixel_22;

    // parameters
    parameter WIDTH  = 128;
    parameter HEIGHT = 128;

    // Line buffers to store the previous two lines of the image
    // 分散RAMは非同期読み出しができるが、BRAMは同期読み出ししかできない。
    reg [7:0] line_buf0 [0:WIDTH-1];
    reg [7:0] line_buf1 [0:WIDTH-1];

    // Shift registers to form the 3-pixel wide sliding window for each of the 3 rows
    reg [7:0] win_row0[0:2], win_row1[0:2], win_row2[0:2];

    // Data read from line buffers (BRAM synchronous read with pre-fetch address)
    reg [7:0] data_from_line0, data_from_line1;
    // 同期読み出ししてもずれが生じないようにするためにread_addrを進めておく
    wire [6:0] read_addr = (col_count == WIDTH-1) ? 7'd0 : col_count + 7'd1;

    always @(posedge clk) begin
        data_from_line0 <= line_buf0[read_addr];
        data_from_line1 <= line_buf1[read_addr];
    end

    // CORE LOGIC: Update line buffers and shift window registers
    always @(posedge clk) begin
        if (enable) begin
            // 1. Update line buffers
            line_buf0[col_count] <= data_from_line1;
            line_buf1[col_count] <= pixel_in;

            // 2. Shift the horizontal window registers
            win_row0[0] <= win_row0[1]; win_row0[1] <= win_row0[2];
            win_row1[0] <= win_row1[1]; win_row1[1] <= win_row1[2];
            win_row2[0] <= win_row2[1]; win_row2[1] <= win_row2[2];

            // 3. Load new data into the right-most column of the window
            // Top row (clamp top edge)
            win_row0[2] <= (row_count == 0) ? data_from_line1 : data_from_line0;
            // Middle row
            win_row1[2] <= data_from_line1;
            // Bottom row (clamp bottom edge)
            win_row2[2] <= pixel_in;
        end
    end

    // Window registers to hold the final clamped 3x3 grid
    reg [7:0] p00, p01, p02, p10, p11, p12, p20, p21, p22;

    // OUTPUT LOGIC: Assign window values and handle horizontal clamping
    always @(posedge clk or negedge xrst) begin
        if (!xrst) begin
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
        end else if (enable && col_count == 0) begin
            p00 <= win_row0[2]; p01 <= win_row1[2]; p02 <= win_row2[2];
            p10 <= win_row0[2]; p11 <= win_row1[2]; p12 <= win_row2[2];
            p20 <= win_row0[2]; p21 <= win_row1[2]; p22 <= win_row2[2];
        end else if (enable && col_count >= 1) begin
            p01 <= win_row0[1]; p11 <= win_row1[1]; p21 <= win_row2[1];

            // Left edge clamp
            if (col_count == 1) begin
                p00 <= win_row0[1]; p10 <= win_row1[1]; p20 <= win_row2[1];
            end else begin
                p00 <= win_row0[0]; p10 <= win_row1[0]; p20 <= win_row2[0];
            end

            // Right edge clamp
            if (col_count == WIDTH - 1) begin
                p02 <= win_row0[1]; p12 <= win_row1[1]; p22 <= win_row2[1];
            end else begin
                p02 <= win_row0[2]; p12 <= win_row1[2]; p22 <= win_row2[2];
            end
        end
    end

    // Final output assignment
    assign pixel_00 = p00; assign pixel_01 = p01; assign pixel_02 = p02;
    assign pixel_10 = p10; assign pixel_11 = p11; assign pixel_12 = p12;
    assign pixel_20 = p20; assign pixel_21 = p21; assign pixel_22 = p22;

endmodule
