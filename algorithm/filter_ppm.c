#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define WIDTH 128
#define HEIGHT 128
#define PIXEL_NUM (WIDTH * HEIGHT)

void filter_v(unsigned char *src, unsigned char *dst) {
  const int w = WIDTH;
  const int h = HEIGHT;

  const int sobel_horizontal[9] = {
    -1, 0, 1,
    -2, 0, 2,
    -1, 0, 1
  };

  const int sobel_vertical[9] = {
    1, 2, 1,
    0, 0, 0,
   -1,-2,-1
  };

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int gx = 0, gy = 0;
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          int ix = x + kx;
          int iy = y + ky;
          
          // unsigned char v = 0;
          // // 画像外はゼロパディング
          // if (ix >= 0 && ix <= w - 1 && iy >= 0 && iy <= h - 1) {
          //     v = src[iy * w + ix];
          // }

          // wrap-around boundary handling
          if (ix < 0) ix = 0;
          if (ix >= w) ix = w - 1;
          if (iy < 0) iy = 0;
          if (iy >= h) iy = h - 1;
          
          unsigned char v = src[iy * w + ix];
          gx += sobel_horizontal[(ky + 1) * 3 + (kx + 1)] * v;
          gy += sobel_vertical[(ky + 1) * 3 + (kx + 1)] * v;
        }
      }
      int sum = abs(gx) + abs(gy);
      // int sum = (int)sqrt(gx * gx + gy * gy);
      if (sum > 255) sum = 255;
      dst[y * w + x] = (unsigned char)sum;
    }
  }
}

int main() {
  FILE *fp_in, *fp_out;
  char buf[128];
  const char *filename_in = "touji.ppm";
  const char *filename_out = "touji_true.ppm";

  unsigned char R_src[PIXEL_NUM], G_src[PIXEL_NUM], B_src[PIXEL_NUM];
  unsigned char R_dst[PIXEL_NUM], G_dst[PIXEL_NUM], B_dst[PIXEL_NUM];

  // 入力
  if ((fp_in = fopen(filename_in, "r")) == NULL) {
    fprintf(stderr, "fail to open '%s'\n", filename_in);
    exit(EXIT_FAILURE);
  }

  // ヘッダー読み飛ばし
  fgets(buf, 128, fp_in); // P3
  do {
    fgets(buf, 128, fp_in); // コメントまたはサイズ
  } while (buf[0] == '#');
  fgets(buf, 128, fp_in); // maxval

  // ピクセル読み込み（R, G, B 順）
  for (int i = 0; i < PIXEL_NUM; i++) {
    int r, g, b;
    fscanf(fp_in, "%d %d %d", &r, &g, &b);
    R_src[i] = (unsigned char)r;
    G_src[i] = (unsigned char)g;
    B_src[i] = (unsigned char)b;
  }
  fclose(fp_in);

  // 各チャンネルに Sobel フィルタ適用
  filter_v(R_src, R_dst);
  filter_v(G_src, G_dst);
  filter_v(B_src, B_dst);

  // 出力
  if ((fp_out = fopen(filename_out, "w")) == NULL) {
    fprintf(stderr, "fail to open '%s'\n", filename_out);
    exit(EXIT_FAILURE);
  }

  fprintf(fp_out, "P3\n%d %d\n255\n", WIDTH, HEIGHT);
  for (int i = 0; i < PIXEL_NUM; i++) {
    fprintf(fp_out, "%d %d %d\n", R_dst[i], G_dst[i], B_dst[i]);
  }
  fclose(fp_out);

  return 0;
}