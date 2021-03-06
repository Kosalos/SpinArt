#pragma once

#include <simd/simd.h>

struct TVertex {
    vector_float3 pos;
    vector_float3 nrm;
    vector_float2 txt;
    vector_float4 color;
    int drawStyle;
};

struct PVertex {
    vector_float3 pos;
    vector_float4 color;
};

struct ConstantData {
    matrix_float4x4 mvp;
    char drawStyle;
    vector_float3 light;

    vector_float4 unused1;
    vector_float4 unused2;
};

struct Uniforms {
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
};


