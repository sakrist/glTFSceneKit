//
//  GLTF+Draco.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 18/04/2018.
//

import Foundation
import SceneKit
import Draco

extension GLTF {
    
    func convertDracoMesh(_ dracoMesh:GLTFKHRDracoMeshCompressionExtension) -> (SCNGeometryElement?, [SCNGeometrySource]?) {
        let bufferViewIndex = dracoMesh.bufferView
        
        if (self.bufferViews?.count)! <= bufferViewIndex {
            return (nil, nil)
        }
        
        let bufferView = self.bufferViews![bufferViewIndex]
        if self.buffers != nil && bufferView.buffer < self.buffers!.count { 
            let buffer = self.buffers![bufferView.buffer]
            if var data = buffer.data(inDirectory:self.directory, cache: false) {
                
                let start = bufferView.byteOffset
                let end = bufferView.byteLength 
                
                if start != 0 && end != data.count {
                    data = data.subdata(in: start..<end)
                }
                
                let (indicesData, verticies, stride) = self.uncompressDracoData(data)
                
                let primitiveCount = (indicesData.count / 12)
                
                let element = SCNGeometryElement.init(data: indicesData,
                                                      primitiveType: .triangles,
                                                      primitiveCount: primitiveCount,
                                                      bytesPerIndex: 4)
                
                
                let byteStride = (bufferView.byteStride != nil) ? bufferView.byteStride! : (stride * 4)
                let count = verticies.count / byteStride
                var byteOffset = 0
                
                var geometrySources = [SCNGeometrySource]()
                
                // sort attributes
                var sortedAttributes:[String] = [String](repeating: "", count: dracoMesh.attributes.count)
                for pair in dracoMesh.attributes {
                    sortedAttributes[pair.value] = pair.key
                }
                
                for key in sortedAttributes {
                    // convert string semantic to SceneKit enum type 
                    let semantic = self.sourceSemantic(name:key)
                    
                    let geometrySource = SCNGeometrySource.init(data: verticies, 
                                                                semantic: semantic, 
                                                                vectorCount: count, 
                                                                usesFloatComponents: true, 
                                                                componentsPerVector: ((semantic == .texcoord) ? 2 : 3) , 
                                                                bytesPerComponent: 4, 
                                                                dataOffset: byteOffset, 
                                                                dataStride: byteStride)
                    geometrySources.append(geometrySource)
                    
                    byteOffset = byteOffset + ((semantic == .texcoord) ? 8 : 12)
                }
                
                return (element, geometrySources)
            } 
        }
        
        return (nil, nil)
    }
    
    /// Decompress draco data
    ///
    /// - Parameter data: draco compressed data
    /// - Returns: Indices data for triangles primitives, Vertices data and stride for vertices data
    func uncompressDracoData(_ data:Data) -> (Data, Data, Int) {
        
        var indicies:Data = Data()
        var verticies:Data = Data()
        var stride:Int = 0
        data.withUnsafeBytes {(uint8Ptr: UnsafePointer<Int8>) in
            
            var verts:UnsafeMutablePointer<Float>?
            var lengthVerts:UInt = 0
            
            var inds:UnsafeMutablePointer<UInt32>?
            var lengthInds:UInt = 0
            
            var descsriptors:UnsafeMutablePointer<DAttributeDescriptor>?
            var descsriptorsCount:UInt = 0
            
            if draco_decode(uint8Ptr, UInt(data.count), &verts, &lengthVerts, &inds, &lengthInds, &descsriptors, &descsriptorsCount, false) {
                
                indicies = Data.init(bytes: UnsafeRawPointer(inds)!, count: Int(lengthInds)*4)
                verticies = Data.init(bytes: UnsafeRawPointer(verts)!, count: Int(lengthVerts)*4)
                for i in 0..<descsriptorsCount {
                    stride += Int(descsriptors![Int(i)].size);
                }
                
                descsriptors?.deinitialize(count: Int(descsriptorsCount))
                descsriptors?.deallocate()
                verts?.deinitialize(count: Int(lengthVerts))
                verts?.deallocate()
                inds?.deinitialize(count: Int(lengthInds))
                inds?.deallocate()
            }
        }
        
        return (indicies, verticies, stride)
    }
}
