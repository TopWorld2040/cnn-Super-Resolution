/**
 *
 * Weights are 4D, indexing formula:
 *   index(w[a,b,n,k]) = a * F_SPATIAL_SIZE * CURRENT_FILTER_COUNT * PREVIOUS_FILTER_COUNT
 *                     + b * CURRENT_FILTER_COUNT * PREVIOUS_FILTER_COUNT
 *                     + k * CURRENT_FILTER_COUNT
 *                     + n
 *  where:
 *    a = 0..F_SPATIAL_SIZE
 *    b = 0..F_SPATIAL_SIZE
 *    n = 0..CURRENT_FILTER_COUNT
 *    k = 0..PREVIOUS_FILTER_COUNT
 *
 * macros:
 *   CURRENT_FILTER_COUNT      filter count for curent layer
 *
 * @param input                output of previous layer, size:
 *                               * 1st layer: img_w * img_h
 *                               * 2nd layer: (img_w-f1+1) * (img_h-f1+1) * n1
 *                               * 3rd layer: (img_w-f1-f2+2) * (img_h-f1-f2+2) * n2
 * @param target               zeroed output buffer, size:
 *                               * 1st layer: (img_w-f1+1) * (img_h-f1+1) * n1
 *                               * 2nd layer: (img_w-f1-f2+2) * (img_h-f1-f2+2) * n2
 *                               * 3rd layer: (img_w-f1-f2-f3+3) * (img_h-f1-f2-f3+3)
 * @param W                    weights, size:
 *                                * 1st layer: f1*f1    per each filter (total: f1*f1*n1)
 *                                * 2nd layer: f2*f2*n1 per each filter (total: f2*f2*n1*n2)
 *                                * 3rd layer: f3*f3*n2
 * @param B                    biases, size:
 *                                * 1st layer: n1
 *                                * 2nd layer: n2
 *                                * 3rd layer: 1
 * @param input_w              source width
 * @param input_h              source height
 */
__kernel
void forward(__read_only __global float* input,
          __global float* target,
          __read_only __global float* W,
          __read_only __global float* B,
          uint input_w, uint input_h){

  // value range: (0..out_w, 0..out_h)
  const int2 pos = {get_global_id(0), get_global_id(1)};
  uint sample_id = get_global_id(2);

  const int2 src_size = {input_w, input_h};
  const int2 out_size = {src_size.x - F_SPATIAL_SIZE + 1,
                         src_size.y - F_SPATIAL_SIZE + 1};

#define IMAGE_OFFSET_IN  sample_id* PREVIOUS_FILTER_COUNT* input_w* input_h
#define IMAGE_OFFSET_OUT sample_id* CURRENT_FILTER_COUNT* out_size.x* out_size.y

  // index on which write to target,
  // will write total of CURRENT_FILTER_COUNT values
  const int out_idx = ((pos.y * out_size.x) + pos.x) * CURRENT_FILTER_COUNT;

  // zeroed result cache
  float vals_by_filter[CURRENT_FILTER_COUNT];
  for (size_t filter_id = 0; filter_id < CURRENT_FILTER_COUNT; filter_id++) {
    vals_by_filter[filter_id] = 0.0f;
  }

  // value range check
  if(pos.x < 0 || pos.x >= out_size.x || //
     pos.y < 0 || pos.y >= out_size.y)
     return;

  // apply weights & write to vals_by_filter
  for (size_t dy = 0; dy < F_SPATIAL_SIZE; dy++) {
    for (size_t dx = 0; dx < F_SPATIAL_SIZE; dx++) {
      int2 input_pos = {pos.x + dx, pos.y + dy};
      int base_input_idx  = ((input_pos.y * input_w) + input_pos.x) * PREVIOUS_FILTER_COUNT;
      size_t w_idx_2D = ((dy * F_SPATIAL_SIZE) + dx) * CURRENT_FILTER_COUNT * PREVIOUS_FILTER_COUNT;

      for (size_t k = 0; k < PREVIOUS_FILTER_COUNT; k++) {
        float point_value = input[IMAGE_OFFSET_IN + base_input_idx + k];
        size_t w_idx_3D = w_idx_2D + k * CURRENT_FILTER_COUNT;

        for (size_t n = 0; n < CURRENT_FILTER_COUNT; n++) {
          vals_by_filter[n] += W[w_idx_3D + n] * point_value;
        }
      }
    }
  }

  // add bias and write cached results to target buffer
  for (size_t filter_id = 0; filter_id < CURRENT_FILTER_COUNT; filter_id++) {
    float result = vals_by_filter[filter_id] + B[filter_id];
#ifdef SKIP_RELU
    target[IMAGE_OFFSET_OUT + out_idx + filter_id] = result;
#else
    target[IMAGE_OFFSET_OUT + out_idx + filter_id] = max(result, 0.0f);
#endif // SKIP_RELU
  }
}
