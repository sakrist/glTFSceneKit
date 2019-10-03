//
//  GLTF+Draco.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 18/04/2018.
//

import Foundation
import SceneKit

// https://github.com/KhronosGroup/glTF/blob/master/extensions/2.0/Khronos/KHR_draco_mesh_compression/README.md

extension GLTF {
    
    func convertDracoMesh(_ dracoMesh:GLTFKHRDracoMeshCompressionExtension, triangleStrip:Bool = true) throws -> (SCNGeometryElement?, [SCNGeometrySource]?) {
        if let (bufferView, data) = try requestData(bufferView: dracoMesh.bufferView) {
            var data = data
            let start = bufferView.byteOffset
            let end = start + bufferView.byteLength
            
            if start != 0 || end != data.count {
                data = data.subdata(in: start..<end)
            }
            
            let (indicesData, verticies, stride) = uncompressDracoData(data, triangleStrip: triangleStrip)
            
            let indexSize = MemoryLayout<UInt32>.size;
            
            let primitiveCount = (triangleStrip) ? ((indicesData.count / indexSize) - 2) : (indicesData.count / (indexSize * 3)) 
            
            let element = SCNGeometryElement.init(data: indicesData,
                                                  primitiveType: ((triangleStrip) ? .triangleStrip : .triangles),
                                                  primitiveCount: primitiveCount,
                                                  bytesPerIndex: indexSize)
            
            
            let byteStride = (bufferView.byteStride != nil) ? bufferView.byteStride! : (stride * 4)
            let count = verticies.count / byteStride
            var byteOffset = 0
            
            var geometrySources = [SCNGeometrySource]()
            
            // sort attributes
            var sortedAttributes:[String] = [String](repeating: "", count: dracoMesh.attributes.count)
            for pair in dracoMesh.attributes {
                sortedAttributes[pair.value] = pair.key
            }
            
            var mtlBuffer:MTLBuffer?
            let device = self.renderer?.device
            verticies.withUnsafeBytes { (unsafeBufferPointer:UnsafeRawBufferPointer) in
                let uint8Ptr = unsafeBufferPointer.bindMemory(to: Int8.self).baseAddress!
                mtlBuffer = device?.makeBuffer(bytes: uint8Ptr, length: verticies.count, options: .storageModeShared)
            }
            
            let createGeometrySource:(SCNGeometrySource.Semantic) -> (SCNGeometrySource)
            if let mtlB = mtlBuffer {
                createGeometrySource = { semantic in
                    let vertexFormat:MTLVertexFormat
                    switch semantic {
                    case .texcoord:
                        vertexFormat = .float2
                    default:
                        vertexFormat = .float3
                    }
                    
                    let geometrySource = SCNGeometrySource.init(buffer: mtlB,
                                                                vertexFormat: vertexFormat,
                                                                semantic: semantic,
                                                                vertexCount: count,
                                                                dataOffset: byteOffset,
                                                                dataStride: byteStride)
                    return geometrySource
                }
                
            } else {
                createGeometrySource = { semantic in
                    let geometrySource = SCNGeometrySource.init(data: verticies,
                                                                semantic: semantic,
                                                                vectorCount: count,
                                                                usesFloatComponents: true,
                                                                componentsPerVector: ((semantic == .texcoord) ? 2 : 3) ,
                                                                bytesPerComponent: 4,
                                                                dataOffset: byteOffset,
                                                                dataStride: byteStride)
                    return geometrySource
                }
            }
            
            for key in sortedAttributes {
                // convert string semantic to SceneKit enum type 
                let semantic = self.sourceSemantic(name:key)
                
                let geometrySource = createGeometrySource(semantic)
                
                geometrySources.append(geometrySource)
                
                byteOffset = byteOffset + ((semantic == .texcoord) ? 8 : 12)
            }
            
            return (element, geometrySources)
        }
        
        return (nil, nil)
    }
}
