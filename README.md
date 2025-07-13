# FPGA-based Sobel Edge Detection Filter

This project implements a hardware-accelerated Sobel edge detection filter using FPGA. The system processes RGB color images through a pipeline architecture combining frame buffers and line buffers for real-time edge detection.

<p>
  <img src="https://github.com/nk12U/sobel-filter-FPGA/blob/main/fig/touji.png" width="200"/>
  <img src="https://github.com/nk12U/sobel-filter-FPGA/blob/main/fig/output.png" width="200"/>
</p>

## Architecture Overview

<img src="https://github.com/nk12U/sobel-filter-FPGA/blob/main/fig/Architecture.png" width="800"/>

### System Design
The system follows a three-stage pipeline architecture:
1. **Input Frame Buffer** (`framebuf_rgb`) - Stores input RGB image data
2. **Sobel Filter Processing** (`sobel_filter`) - Performs edge detection using line buffers
3. **Output Frame Buffer** (`framebuf_rgb`) - Stores processed edge-detected image

### Key Components

#### Top-level Module (`top.v`)
- Connects input/output frame buffers with the Sobel filter
- Manages data flow between pipeline stages
- Handles RGB 24-bit pixel data (8-bit per channel)

#### Sobel Filter (`sobel_filter.v`)
- **Multi-channel Processing**: Processes R, G, B channels independently using separate line buffers
- **Position Tracking**: Maintains `row_count` and `col_count` for boundary condition handling
- **Pipeline Stages**: 
  - Stage 0: Line buffer extraction
  - Stage 1: Sobel kernel computation  
  - Stage 2: Output registration

#### Line Buffer (`line_buffer.v`)
- **3×3 Window Extraction**: Implements sliding window using line buffers and shift registers
- **BRAM Optimization**: Uses synchronous reads for efficient Block RAM inference
- **Boundary Handling**: Edge clamping for pixels at image boundaries
- **Memory Structure**: Two line buffers (`line_buf0`, `line_buf1`) store previous image lines

#### Sobel Kernel (`sobel_kernel.v`)
- **Convolution Implementation**: Applies horizontal and vertical Sobel kernels
- **Gradient Calculation**: 
  - Horizontal: `[-1,0,1; -2,0,2; -1,0,1]`
  - Vertical: `[1,2,1; 0,0,0; -1,-2,-1]`
- **Edge Magnitude**: Computes `|gx| + |gy|` using Manhattan distance

### Data Flow

1. **Input Processing**: 128×128 RGB images enter through `framebuf_rgb`
2. **Line Buffer Stage**: Each color channel is processed through separate line buffers
3. **3×3 Window Formation**: Line buffers provide neighborhood access for convolution
4. **Sobel Computation**: Parallel processing of R, G, B channels
5. **Output Generation**: Edge-detected image stored in output frame buffer

### Technical Specifications

- **Image Resolution**: 128×128 pixels
- **Data Width**: 24-bit RGB (8-bit per channel)
- **Memory**: Block RAM optimized line buffers
- **Target Device**: Cyclone IV E (EP4CE115F29C7)
- **IDE Environment**: Quartus Prime 24.1std
- **Simulation**: ModelSim 20.1
- **Clock Frequency**: 50MHz (20ns period)

### Design Constraints

#### Boundary Conditions
- **Top 2 Rows**: Cannot generate valid 3×3 windows due to insufficient line buffer history
- **Output Limitation**: Effective output covers rows 2-127 (126 rows total)
- **Edge Handling**: Pixel clamping applied at left/right boundaries

#### Memory Architecture
- **Line Buffer Depth**: 128 pixels per line
- **History Requirements**: 2 lines of pixel data for 3×3 neighborhood
- **BRAM Inference**: Synchronous read operations for optimal memory utilization

### File Structure

```
RTL/
├── top.v              # Top-level module
├── sobel_filter.v     # Main Sobel filter with RGB processing
├── sobel_kernel.v     # Sobel convolution kernel
├── line_buffer.v      # Line buffer for 3×3 window extraction
├── framebuf_rgb.v     # RGB frame buffer
├── test_top.v         # test bench 

algorithm/
├── filter_ppm.c       # Reference C implementation
```

### Testing and Validation

The design includes comprehensive simulation environment with:
- **Reference Implementation**: C-based Sobel filter (`filter_ppm.c`)
- **Test Images**: PPM format RGB images for validation
- **Simulation Scripts**: test_top.v
- **Output Verification**: Comparison between FPGA and software results

### Known Limitations

1. **Initial Line Buffer Filling**: First 256 pixels (2 rows) require initialization
2. **Output Coverage**: Reduced effective output area due to boundary constraints
3. **Pipeline Latency**: 3-stage pipeline introduces processing delay

This implementation demonstrates efficient FPGA-based image processing with optimized memory usage and parallel RGB channel processing for real-time edge detection applications.
