//
//  GLTF+Material.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation
import SceneKit

extension GLTF {
    
    var cache_materials:[SCNMaterial?]? {
        get { return objc_getAssociatedObject(self, &Keys.cache_materials) as? [SCNMaterial?] }
        set { objc_setAssociatedObject(self, &Keys.cache_materials, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Material
    
    // load material by index
    func loadMaterial(index:Int, completionHandler: @escaping (SCNMaterial) -> Void) {
        
        if self.materials == nil || index >= (self.materials?.count)! {
            completionHandler(SCNMaterial())
            return
        }
        
        let material = self.materials![index]
        
        os_unfair_lock_lock(&material.lock)
        var scnMaterial_ = self.cache_materials![index]
        if scnMaterial_ == nil {
            scnMaterial_ = SCNMaterial()
        } else {
            if material.loading {
                material.waitingStack.append(completionHandler)
            } else {
                completionHandler(scnMaterial_!.copy() as! SCNMaterial)
            }
            os_unfair_lock_unlock(&material.lock)
            return
        }
        material.loading = true
        let scnMaterial = scnMaterial_!
        self.cache_materials![index] = scnMaterial
        os_unfair_lock_unlock(&material.lock)
        
        
        scnMaterial.name = material.name
        scnMaterial.isDoubleSided = material.doubleSided
        
        if let pbr = material.pbrMetallicRoughness {
            scnMaterial.lightingModel = .physicallyBased
            if let baseTextureInfo = pbr.baseColorTexture {
                self.loadTexture(index:baseTextureInfo.index, property: scnMaterial.diffuse)
            } else {
                let color = (pbr.baseColorFactor.count < 4) ? [1, 1, 1, 1] : (pbr.baseColorFactor)
                scnMaterial.diffuse.contents = ColorClass(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: CGFloat(color[3]))
            }
            scnMaterial.transparency = CGFloat(pbr.baseColorFactor[3])
            
            if let metallicRoughnessTextureInfo = pbr.metallicRoughnessTexture {
                if #available(OSX 10.13, iOS 11.0, *) {
                    scnMaterial.metalness.textureComponents = .blue
                    scnMaterial.roughness.textureComponents = .green
                    self.loadTexture(index:metallicRoughnessTextureInfo.index, property: scnMaterial.metalness)
                    self.loadTexture(index:metallicRoughnessTextureInfo.index, property: scnMaterial.roughness)
                } else {
                    // Fallback on earlier versions
                    if self.textures != nil &&  metallicRoughnessTextureInfo.index < (self.textures?.count)! {
                        let texture = self.textures![metallicRoughnessTextureInfo.index]
                        if texture.source != nil {
                            
                            loadSampler(sampler:texture.sampler, property: scnMaterial.roughness)
                            loadSampler(sampler:texture.sampler, property: scnMaterial.metalness)
                            
                            let image = self.image(byIndex:texture.source!)
                            if let images = try? image?.channels() {
                                scnMaterial.roughness.contents = images?[1]
                                scnMaterial.metalness.contents = images?[2]
                            }
                        }
                    }
                }
                
            } else {
                scnMaterial.metalness.contents = pbr.metallicFactor
                scnMaterial.roughness.contents = pbr.roughnessFactor
                scnMaterial.fresnelExponent = 0.04
            }
        }
        
        if let normalTextureInfo = material.normalTexture {
            self.loadTexture(index: normalTextureInfo.index!, property: scnMaterial.normal)
        }
        
        if let occlusionTextureInfo = material.occlusionTexture {
            self.loadTexture(index: occlusionTextureInfo.index!, property: scnMaterial.ambientOcclusion)
            scnMaterial.ambientOcclusion.intensity = CGFloat(occlusionTextureInfo.strength)
        }
        
        if let emissiveTextureInfo = material.emissiveTexture {
            self.loadTexture(index: emissiveTextureInfo.index, property: scnMaterial.emission)
        } else {
            let color = (material.emissiveFactor.count < 3) ? [1, 1, 1] : (material.emissiveFactor)
            scnMaterial.emission.contents = SCNVector4Make(SCNFloat(color[0]), SCNFloat(color[1]), SCNFloat(color[2]), 1.0)
        }
        
        material.loading = false
        
        completionHandler(scnMaterial)
        var iterator = material.waitingStack.makeIterator()
        while let completionHandler = iterator.next() {
            completionHandler(scnMaterial.copy() as! SCNMaterial)
        }
        material.waitingStack.removeAll()
        
    }
    
    // get image by index
    fileprivate func image(byIndex index:Int) -> ImageClass? {
        if let gltf_image = self.images?[index] {
            if let image = try? self.loader.load(resource: gltf_image) {
                return image
            }
        }
        return nil
    }
    
    
    /// Load texture by index.
    ///
    /// - Parameters:
    ///   - index: index of GLTFTexture in textures
    ///   - property: material's property
    fileprivate func loadTexture(index:Int, property:SCNMaterialProperty) {
        if self.textures != nil && index < self.textures!.count {
            let texture = self.textures![index]
            
            os_unfair_lock_lock(&texture.lock)
            
            loadSampler(sampler:texture.sampler, property: property)
            
            var loaded = false
            
            if texture.extras != nil && texture.extras!["texture"] != nil {
                property.contents = texture.extras!["texture"]
                loaded = true
            } else if (texture.extensions != nil) {
                if let descriptor = (texture.extensions![compressedTextureExtensionKey] as? GLTF_3D4MCompressedTextureExtension) {   
                    if let textureCompressed = createCompressedTexture(descriptor) {
                        texture.extras = ["texture":textureCompressed as Any]
                        property.contents = textureCompressed
                        loaded = true
                    }
                }
            }
            
            if texture.source != nil && !loaded {
                let loadedImage = self.image(byIndex:texture.source!)
                texture.extras = ["texture":loadedImage as Any]
                property.contents = loadedImage
            }
            
            os_unfair_lock_unlock(&texture.lock)
        }
    }
    
    
    fileprivate func loadSampler(sampler samplerIndex:Int?, property:SCNMaterialProperty) {
        if samplerIndex != nil && self.samplers != nil && samplerIndex! < self.samplers!.count {
            let sampler = self.samplers![samplerIndex!]
            property.wrapS = sampler.wrapS.scn()
            property.wrapT = sampler.wrapT.scn()
            property.magnificationFilter = sampler.magFilterScene()
            (property.minificationFilter, property.mipFilter)  = sampler.minFilterScene()
        }
    }
}


extension GLTFSampler {
    fileprivate func magFilterScene() -> SCNFilterMode {
        if self.magFilter != nil {
            return (self.magFilter?.scn())!
        }
        return .none
    }
    
    fileprivate func minFilterScene() -> (SCNFilterMode, SCNFilterMode) {
        if self.minFilter != nil {
            return (self.minFilter?.scn())!
        }
        return (.none, .none)
    }
}

extension GLTFSamplerMagFilter {
    fileprivate func scn() -> SCNFilterMode {
        switch self {
        case .LINEAR:
            return .linear
        case .NEAREST:
            return .nearest
        }
    }
}

extension GLTFSamplerMinFilter {
    fileprivate func scn() -> (SCNFilterMode, SCNFilterMode) {
        switch self {
        case .LINEAR:
            return (.linear, .none)
        case .NEAREST:
            return (.nearest, .none)
        case .LINEAR_MIPMAP_LINEAR:
            return (.linear, .linear)
        case .NEAREST_MIPMAP_NEAREST:
            return (.nearest, .nearest)
        case .LINEAR_MIPMAP_NEAREST:
            return (.linear, .nearest)
        case .NEAREST_MIPMAP_LINEAR:
            return (.nearest, .linear)
        }
    }
}

extension GLTFSamplerWrapS {
    fileprivate func scn() -> SCNWrapMode {
        switch self {
        case .CLAMP_TO_EDGE:
            return .clampToBorder
        case .REPEAT:
            return .repeat
        case .MIRRORED_REPEAT:
            return .mirror
        }
    }
}

extension GLTFSamplerWrapT {
    fileprivate func scn() -> SCNWrapMode {
        switch self {
        case .CLAMP_TO_EDGE:
            return .clampToBorder
        case .REPEAT:
            return .repeat
        case .MIRRORED_REPEAT:
            return .mirror
        }
    }
}

extension GLTFMaterial {
    static var loading_flag_key = "loading_flag_key"
    static var waiting_stack_key = "waiting_stack_key"
    
    var loading:Bool {
        get { return (objc_getAssociatedObject(self, &GLTFMaterial.loading_flag_key) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &GLTFMaterial.loading_flag_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var waitingStack:[(SCNMaterial) -> Void] {
        get {
            var waitingStack_ = objc_getAssociatedObject(self, &GLTFMaterial.waiting_stack_key) as? [(SCNMaterial) -> Void]
            if waitingStack_ == nil {
                waitingStack_ = [(SCNMaterial) -> Void]()
                self.waitingStack = waitingStack_!
            }
            return waitingStack_! 
            
        }
        set { objc_setAssociatedObject(self, &GLTFMaterial.waiting_stack_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
