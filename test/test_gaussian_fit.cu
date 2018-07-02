#include "gtest/gtest.h"

#include "test_utils.h"

#include "cuda_runtime.h"

#include "../src/matrix.h"
#include "../src/matrix_fill.h"
#include "../src/matrix_copy.h"
#include "../src/matrix_peak_threshold.h"
#include "../src/gaussian_fit.h"



TEST(residual_jacobian, Valid)
{
  matrix_t cmap_mat;
  matrix_set_shape(&cmap_mat, 4, 4);

  // create cmap data
  float cmap_data_h[4 * 4] = {
    0, 0.5, 0, 0,
    0.5, 1.0, 0.5, 0,
    0, 0.5, 0, 0,
    0, 0, 0, 0,
  };
  const int max_idx = 5;
  //float cmap_data_h[4 * 4];
  //matrix_copy_h2h_transpose(&cmap_mat, cmap_data_h_transp, cmap_data_h);

  // copy cmap to device
  float *cmap_data_d;
  matrix_malloc_d(&cmap_mat, &cmap_data_d);
  matrix_copy_h2d(&cmap_mat, cmap_data_h, cmap_data_d);

  // create optimization matrices
  const uint8_t N = 3;
  matrix_t jacobian_mat, residual_mat, param_mat;
  matrix_set_shape(&jacobian_mat, N * N, 4);
  matrix_set_shape(&residual_mat, N * N, 1);
  matrix_set_shape(&param_mat, 4, 1);

  float *jacobian_data_h, *residual_data_h, *param_data_h;
  float *jacobian_data_d, *residual_data_d, *param_data_d;
  matrix_malloc_d(&jacobian_mat, &jacobian_data_d);
  matrix_malloc_d(&residual_mat, &residual_data_d);
  matrix_malloc_d(&param_mat, &param_data_d);

  matrix_malloc_h(&jacobian_mat, &jacobian_data_h);
  matrix_malloc_h(&residual_mat, &residual_data_h);
  matrix_malloc_h(&param_mat, &param_data_h);
  
  // initialize parameters
  param_data_h[0] = 1.0;
  param_data_h[1] = 1.0;
  param_data_h[2] = 1.0;
  param_data_h[3] = 1.0;
  matrix_copy_h2d(&param_mat, param_data_h, param_data_d);

  // true jacobian
  float jacobian_data_true_transp_h[] = {
    0.36787944,  0.36787944, -0.36787944, -0.36787944,
    0.60653066, -0.        , -0.60653066, -0.30326533,
    0.36787944, -0.36787944, -0.36787944, -0.36787944,
    -0.        ,  0.60653066, -0.60653066, -0.30326533,
    -0.        , -0.        , -1.        , -0.        ,
    -0.        , -0.60653066, -0.60653066, -0.30326533,
    -0.36787944,  0.36787944, -0.36787944, -0.36787944,
    -0.60653066, -0.        , -0.60653066, -0.30326533,
    -0.36787944, -0.36787944, -0.36787944, -0.36787944
  };
  float jacobian_data_true_h[N * N * 4];
  matrix_copy_h2h_transpose(&jacobian_mat, jacobian_data_true_transp_h, jacobian_data_true_h);

  // true residual
  float residual_data_true_h[] = {
    -0.36787944, -0.10653066, -0.36787944, -0.10653066,  0.        , -0.10653066, -0.36787944, -0.10653066, -0.36787944
  };

  // compute residual jacobian
  residual_jacobian_d(max_idx, N, cmap_data_d, &cmap_mat, residual_data_d, &residual_mat, jacobian_data_d, &jacobian_mat, param_data_d, &param_mat);

  matrix_copy_d2h(&jacobian_mat, jacobian_data_d, jacobian_data_h);
  matrix_copy_d2h(&residual_mat, residual_data_d, residual_data_h);
  matrix_copy_d2h(&param_mat, param_data_d, param_data_h);

  AllFloatEqual(jacobian_data_true_h, jacobian_data_h, matrix_size(&jacobian_mat));
  AllFloatEqual(residual_data_true_h, residual_data_h, matrix_size(&residual_mat));

  cudaFree(cmap_data_d);
  cudaFree(jacobian_data_d);
  cudaFree(residual_data_d);
  cudaFree(param_data_d);

  free(jacobian_data_h);
  free(residual_data_h);
  free(param_data_h);
}

TEST(residual_jacobian, ValidNonCentered)
{
  matrix_t cmap_mat;
  matrix_set_shape(&cmap_mat, 4, 4);

  // create cmap data
  float cmap_data_h[4 * 4] = {
    0.0, 0.3, 0.0, 0.0,
    0.3, 0.7, 0.2, 0.0,
    0.0, 0.3, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0,
  };
  const int max_idx = 5;
  //float cmap_data_h[4 * 4];
  //matrix_copy_h2h_transpose(&cmap_mat, cmap_data_h_transp, cmap_data_h);

  // copy cmap to device
  float *cmap_data_d;
  matrix_malloc_d(&cmap_mat, &cmap_data_d);
  matrix_copy_h2d(&cmap_mat, cmap_data_h, cmap_data_d);

  // create optimization matrices
  const uint8_t N = 3;
  matrix_t jacobian_mat, residual_mat, param_mat;
  matrix_set_shape(&jacobian_mat, N * N, 4);
  matrix_set_shape(&residual_mat, N * N, 1);
  matrix_set_shape(&param_mat, 4, 1);

  float *jacobian_data_h, *residual_data_h, *param_data_h;
  float *jacobian_data_d, *residual_data_d, *param_data_d;
  matrix_malloc_d(&jacobian_mat, &jacobian_data_d);
  matrix_malloc_d(&residual_mat, &residual_data_d);
  matrix_malloc_d(&param_mat, &param_data_d);

  matrix_malloc_h(&jacobian_mat, &jacobian_data_h);
  matrix_malloc_h(&residual_mat, &residual_data_h);
  matrix_malloc_h(&param_mat, &param_data_h);
  
  // initialize parameters
  param_data_h[0] = 1.0;
  param_data_h[1] = 1.0;
  param_data_h[2] = 1.0;
  param_data_h[3] = 1.0;
  matrix_copy_h2d(&param_mat, param_data_h, param_data_d);

  // true jacobian
  float jacobian_data_true_transp_h[] = {
    0.36787944,  0.36787944, -0.36787944, -0.36787944,
    0.60653066, -0.        , -0.60653066, -0.30326533,
    0.36787944, -0.36787944, -0.36787944, -0.36787944,
    -0.        ,  0.60653066, -0.60653066, -0.30326533,
    -0.        , -0.        , -1.        , -0.        ,
    -0.        , -0.60653066, -0.60653066, -0.30326533,
    -0.36787944,  0.36787944, -0.36787944, -0.36787944,
    -0.60653066, -0.        , -0.60653066, -0.30326533,
    -0.36787944, -0.36787944, -0.36787944, -0.36787944
  };
  float jacobian_data_true_h[N * N * 4];
  matrix_copy_h2h_transpose(&jacobian_mat, jacobian_data_true_transp_h, jacobian_data_true_h);

  // true residual
  float residual_data_true_h[] = {
    -0.36787944, -0.30653066, -0.36787944, -0.30653066, -0.3       , -0.40653066, -0.36787944, -0.30653066, -0.36787944
  };

  // compute residual jacobian
  residual_jacobian_d(max_idx, N, cmap_data_d, &cmap_mat, residual_data_d, &residual_mat, jacobian_data_d, &jacobian_mat, param_data_d, &param_mat);

  matrix_copy_d2h(&jacobian_mat, jacobian_data_d, jacobian_data_h);
  matrix_copy_d2h(&residual_mat, residual_data_d, residual_data_h);
  matrix_copy_d2h(&param_mat, param_data_d, param_data_h);

  AllFloatEqual(jacobian_data_true_h, jacobian_data_h, matrix_size(&jacobian_mat));
  AllFloatEqual(residual_data_true_h, residual_data_h, matrix_size(&residual_mat));

  cudaFree(cmap_data_d);
  cudaFree(jacobian_data_d);
  cudaFree(residual_data_d);
  cudaFree(param_data_d);

  free(jacobian_data_h);
  free(residual_data_h);
  free(param_data_h);
}

#ifndef EXCLUDE_MAIN
int main(int argc, char *argv[])
{
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
#endif
