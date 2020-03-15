//
//  Shaders.metal
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 28/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float4 renderedCoordinate [[position]];
    float2 textureCoordinate;
} TextureMappingVertex;

struct camera {
    float front;
};

vertex TextureMappingVertex mapTexture(unsigned int vertex_id [[ vertex_id ]], constant camera& cameras [[ buffer(0) ]]) {
    
    float4x4 renderedCoordinates = float4x4(float4( 1.0 * cameras.front, -1.0, 0.0, 1.0),
                                            float4(-1.0 * cameras.front, -1.0, 0.0, 1.0),
                                            float4( 1.0 * cameras.front,  1.0, 0.0, 1.0),
                                            float4(-1.0 * cameras.front,  1.0, 0.0, 1.0));

    float4x2 textureCoordinates = float4x2(float2(1.0, 0.0),
                                           float2(1.0, 1.0),
                                           float2(0.0, 0.0),
                                           float2(0.0, 1.0));
    
    TextureMappingVertex outVertex;
    outVertex.renderedCoordinate = renderedCoordinates[vertex_id];
    outVertex.textureCoordinate = textureCoordinates[vertex_id];
    
    return outVertex;
}

constant half3 luminanceWeighting = half3(0.2125, 0.7154, 0.0721);

fragment half4 displayTexture(TextureMappingVertex mappingVertex [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler s(address::clamp_to_edge, filter::linear);

    
    half4 out = half4(texture.sample(s, mappingVertex.textureCoordinate));

    // Contrast
    float contrast = 1.0; // Elliott (contrast) 1.0 is normal. 2.0 is charcoal.
    float saturation = 1.0; // Elliott (saturation) 1.0 is normal. 4.0 is hypnotic. 0.0 is grayscale.
    
    out = half4(((out.rgb - half3(0.5)) * contrast + half3(0.5)), out.a);

    half luminance = dot(out.rgb, luminanceWeighting);
    
    return half4(mix(half3(luminance), out.rgb, half(saturation)), out.a);

}

/*
 
 fragment half4 saturationFragment(
 SingleInputVertexIO fragmentInput [[stage_in]],
 texture2d inputTexture [[texture(0)]],
 constant SaturationUniform& uniform [[ buffer(1) ]])
 {
 constexpr sampler quadSampler;
 half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
 
 half luminance = dot(color.rgb, luminanceWeighting);
 
 return half4(mix(half3(luminance), color.rgb, half(uniform.saturation)), color.a);
 }
 
 
 */


/*
fragment half4 contrastFragment(
                                SingleInputVertexIO fragmentInput [[stage_in]],
                                texture2d inputTexture [[texture(0)]],
                                constant ContrastUniform& uniform [[ buffer(1) ]])
{
    constexpr sampler quadSampler;
    half4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);
    
    return half4(((color.rgb - half3(0.5)) * uniform.contrast + half3(0.5)), color.a);
}
*/
