#include <metal_stdlib>
using namespace metal;


kernel void computeShader(uint              index   [[ thread_position_in_grid ]],
                          constant  float   *inA    [[ buffer(0) ]],
                          constant  float   *inB    [[ buffer(1) ]],
                          device    float   *result [[ buffer(2) ]]
                          ) {

    result[index] = inA[index] + inB[index];
}
