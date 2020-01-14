#include <metal_stdlib>
#include <simd/simd.h>
#import "ShaderTypes.h"

using namespace metal;

struct Transfer {
    float4 position [[position]];
    float pointsize [[point_size]];
    float2 txt;
    float4 color;
    float4 lighting;
    uchar drawStyle;
};

vertex Transfer texturedVertexShader
(
 constant TVertex* vData [[ buffer(0) ]],
 constant ConstantData& constantData [[ buffer(1) ]],
 unsigned int vid [[ vertex_id ]])
{
    Transfer out;
    TVertex v = vData[vid];
    
    out.pointsize = 12.0;
    out.color = v.color;
    out.drawStyle = v.drawStyle;
    out.position = constantData.mvp * float4(v.pos, 1.0);
    
    if(v.drawStyle == 1) {
        float3 nrm = vData[vid].nrm;
        float intensity = saturate(dot(nrm.rgb, constantData.light));
        out.lighting = float4(intensity,intensity,intensity,1);
    }
    
    return out;
}

fragment float4 texturedFragmentShader
(Transfer data [[stage_in]],
 texture2d<float> tex2D [[texture(0)]])
{
    if(data.drawStyle == 0) return data.color;
    
    return data.color * data.lighting;
}
