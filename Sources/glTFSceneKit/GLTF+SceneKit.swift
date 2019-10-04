//
//  GLTF+Extension.swift
//  
//
//  Created by Volodymyr Boichentsov on 13/10/2017.
//  Copyright © 2017 Volodymyr Boichentsov. All rights reserved.
//

import Foundation
import SceneKit
import os

let log_scenekit = OSLog(subsystem: "org.glTFSceneKit", category: "scene")

let dracoExtensionKey = "KHR_draco_mesh_compression"
let compressedTextureExtensionKey = "3D4M_compressed_texture"
let supportedExtensions = [dracoExtensionKey, compressedTextureExtensionKey]


struct ConvertionProgressMask : OptionSet {
    let rawValue: Int
    
    static let nodes  = ConvertionProgressMask(rawValue: 1 << 1)
    static let textures = ConvertionProgressMask(rawValue: 1 << 2)
    static let animations  = ConvertionProgressMask(rawValue: 1 << 3)
    
    static func all() -> ConvertionProgressMask {
        return [.nodes, .textures, .animations]
    }
}


@objc public protocol SceneLoadingDelegate {
    @objc optional func scene(_ didLoadScene: SCNScene )
    @objc optional func scene(_ scene: SCNScene, didCreate camera: SCNCamera)
    @objc optional func scene(_ scene: SCNScene, didCreate node: SCNNode)
    @objc optional func scene(_ scene: SCNScene, didCreate material: SCNMaterial, for node: SCNNode)
}

extension GLTF {
        
    struct Keys {
        static var resource_loader = "resource_loader"
        static var load_canceled = "load_canceled"
    }
    
    /// Status set to true if `cancel` been call.
    @objc open private(set) var isCancelled:Bool {
        get { return (objc_getAssociatedObject(self, &Keys.load_canceled) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Keys.load_canceled, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    internal func cancel() {
        self.isCancelled = true
        self.loader.cancelAll()
    }
    
    internal func clearCache() {
        if self.buffers != nil {
            for buffer in self.buffers! {
                buffer.data = nil
            }
        }
        
        if self.images != nil {
            for image in self.images! {
                image.image = nil
            }
        }
    }
    
    // convert attributes name to SceneKit semantic
    internal static func sourceSemantic(name:String) -> SCNGeometrySource.Semantic {
        switch name {
        case "POSITION":
            return .vertex
        case "NORMAL":
            return .normal
        case "TANGENT":
            return .tangent
        case "COLOR", "COLOR_0", "COLOR_1", "COLOR_2":
            return .color
        case "TEXCOORD_0", "TEXCOORD_1", "TEXCOORD_2", "TEXCOORD_3", "TEXCOORD_4":
            return .texcoord
        case "JOINTS_0":
            return .boneIndices
        case "WEIGHTS_0":
            return .boneWeights
        default:
            return .vertex
        }
    }
    
    internal static func requestData(glTF: GLTF, bufferView:Int) throws -> (GLTFBufferView, Data)? {
        if let bufferView = glTF.bufferViews?[bufferView] {
            if let buffer = glTF.buffers?[bufferView.buffer] {
                
                if let data = try glTF.loader.load(gltf:glTF, resource: buffer) {
                    return (bufferView, data)
                }
            } else {
                throw GLTFError("Can't load data! Can't find buffer at index \(bufferView.buffer)")
            }
        } else {
            throw GLTFError("Can't load data! Can't find bufferView at index \(bufferView)")
        }
        return nil
    }
    
}
