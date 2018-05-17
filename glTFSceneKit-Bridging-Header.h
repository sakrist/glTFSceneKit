//
//  glTFSceneKit.h
//  glTFSceneKit
//
//  Created by Volodymyr Boichentsov on 17/05/2018.
//

#ifndef glTFSceneKit_h
#define glTFSceneKit_h

#include <stdbool.h> 

typedef enum {
    DAttributeVertex = 0, // draco::GeometryAttribute::POSITION
    DAttributeNormal, // draco::GeometryAttribute::NORMAL
    DAttributeColor, // draco::GeometryAttribute::COLOR
    DAttributeTexCoord, // draco::GeometryAttribute::TEX_COORD
    DAttributeGeneric, // у на tangent, но это draco::GeometryAttribute::GENERIC
    DAttributeCount
} DAttribute;

struct DAttributeDescriptor {
    DAttribute name;
    short size;
};

#if __cplusplus
extern "C" {
#endif
    
    /**
     Encode mesh from float buffer (vertices) and indices to compressed data - buffer vector<char>.
     Array initializes inside and should be deleted by hands
     
     @param vertices      - geometryData
     @param vertLength    - length of vertices
     @param indices       - indexData
     @param indicesLength - length of indexData
     @param elements      - array with bufferElements by order
     @param elemCount     - size of elements
     @param quantization  - affects encodig/decoding time, model quality and buffer size.
     14 - optimal value, smaller then 10 gives losses in geometry.
     @param bufferOut       - output - encoded buffer
     @param bufferOutLength - output length of bufferOut
     */
    bool draco_encode(float *vertices, unsigned long vertLength, unsigned int* indices, unsigned long indicesLength, struct DAttributeDescriptor *elements, const short elemCount, int quantization, char** bufferOut, unsigned long *bufferOutLength);
    
    /**
     Decode Buffer and write mesh to vertex and index arrays
     Arrays initializes inside and should be deleted by hands
     
     @param buffer       - input buffer data - char*
     @param bufferLength - input buffer length
     @param verticesOut  - output vertices data - float*
     @param vertLength   - output length of verticesOut
     @param indicesOut   - output indices data - unsigned int*
     @param indLength    - output length of indicesOut
     @param descriptorOut- output array with bufferElements by order
     @param descriptorOutLength - size of descriptorOut
     return false on error
     */
    bool draco_decode(const char* buffer, unsigned long bufferLength, float** verticesOut, unsigned long* vertLength, unsigned int** indicesOut, unsigned long *indLength, struct DAttributeDescriptor** descriptorOut, unsigned long *descriptorOutLength, bool triangleStrip);
    
    
#if __cplusplus
}
#endif

#endif /* glTFSceneKit_h */
