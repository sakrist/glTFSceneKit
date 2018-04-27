//
//  GLTF+Material.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation
import SceneKit

// Texture load status
enum TextureStatus:Int {
    case no = 0
    case loading
    case loaded
}

class TextureAssociator {
    var status:TextureStatus = .no
    
    private var content_:Any?
    var content:Any? {
        set { 
            content_ = newValue
            if (newValue != nil) {
                self.status = .loaded
                
                for property in associatedProperties {
                    property.contents = content_
                }
            }
        }
        get {
            return content_
        }
    }
    
    lazy var associatedProperties = Set<SCNMaterialProperty>() 
    
    func associate(property:SCNMaterialProperty) {
        associatedProperties.insert(property)
        property.contents = content
    }
}

class TextureStorageManager {
    
    static let manager = TextureStorageManager()
    
    private var worker = DispatchQueue(label: "textures_loader")
    
    lazy private var _associators:[Int : TextureAssociator] = [Int : TextureAssociator]()
    
    private var lock = os_unfair_lock_s()
    
    func textureAssociator(at index:Int) -> TextureAssociator {
        os_unfair_lock_lock(&lock)
        var tStatus = _associators[index] 
        if tStatus == nil {
            tStatus = TextureAssociator()
            _associators[index] = tStatus
        }
        os_unfair_lock_unlock(&lock)
        return tStatus!
    }
    
    /// Load texture by index.
    ///
    /// - Parameters:
    ///   - index: index of GLTFTexture in textures
    ///   - property: material's property
    func loadTexture( gltf:GLTF, index:Int, property:SCNMaterialProperty) {
        guard let texture = gltf.textures?[index] else {
            print("Failed to find texture")
            return
        } 
            
        worker.async {
            let tStatus = self.textureAssociator(at:index)
            
            if tStatus.status == .no {
                tStatus.status = .loading
                tStatus.associate(property: property)
                
                gltf.loadSampler(sampler:texture.sampler, property: property)
                
                if let descriptor = texture.extensions?[compressedTextureExtensionKey] {
                    // load first level mipmap as texture
                    gltf.loadCompressedTexture(descriptor:descriptor as! GLTF_3D4MCompressedTextureExtension, firstLevel: true) { cTexture, error in        
                        
                        if (error != nil) {
                            print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                            self._loadImageTexture(gltf, texture, tStatus)
                        } else {
                            tStatus.content = cTexture as Any?
                            
                            // load all levels
                            gltf.loadCompressedTexture(descriptor:descriptor as! GLTF_3D4MCompressedTextureExtension, firstLevel: false) { (cTexture2, error) in
                                if (error != nil) {
                                    print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                                    self._loadImageTexture(gltf, texture, tStatus)
                                } else {
                                    tStatus.content = cTexture2 as Any?
                                }
                            }
                        }
                    }
                } else {
                    self._loadImageTexture(gltf, texture, tStatus)
                }
            } else {
                tStatus.associate(property: property)
            }
        }
    }
    
    // load original image source
    func _loadImageTexture(_ gltf:GLTF, _ texture:GLTFTexture, _ tStatus:TextureAssociator) {
        DispatchQueue.global().async {
            var textureResult:OSImage?
            if let imageSourceIndex = texture.source {
                if let gltf_image = gltf.images?[imageSourceIndex] {
                    do {
                        textureResult = try gltf.loader.load(resource: gltf_image)
                    } catch {
                        print("Failed to load image. \(error)")
                    }
                }
            }
            if textureResult != nil {
                tStatus.content = gltf._compress(image:textureResult!)
            }
        }
    }
}



extension GLTF {
    
    // MARK: - Material
    
    // load material by index
    func loadMaterial(index:Int, completionHandler: @escaping (SCNMaterial) -> Void) {
        
        if let material = self.materials?[index] {
            let scnMaterial = SCNMaterial()
            scnMaterial.name = material.name
            scnMaterial.isDoubleSided = material.doubleSided
            
            if let pbr = material.pbrMetallicRoughness {
                
                // set PBR type
                scnMaterial.lightingModel = .physicallyBased
                
                if let baseTextureInfo = pbr.baseColorTexture {
                    TextureStorageManager.manager.loadTexture(gltf:self, index:baseTextureInfo.index, property: scnMaterial.diffuse)
                } else {
                    let color = (pbr.baseColorFactor.count < 4) ? [1, 1, 1, 1] : (pbr.baseColorFactor)
                    scnMaterial.diffuse.contents = OSColor(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: CGFloat(color[3]))
                }
                
                // transparency/opacity
                scnMaterial.transparency = CGFloat(pbr.baseColorFactor[3])
                
                if let metallicRoughnessTextureInfo = pbr.metallicRoughnessTexture {
                    if #available(OSX 10.13, iOS 11.0, *) {
                        scnMaterial.metalness.textureComponents = .blue
                        scnMaterial.roughness.textureComponents = .green
                        TextureStorageManager.manager.loadTexture(gltf:self, index:metallicRoughnessTextureInfo.index, property: scnMaterial.metalness)
                        TextureStorageManager.manager.loadTexture(gltf:self, index:metallicRoughnessTextureInfo.index, property: scnMaterial.roughness)
                    } else {
                        // Fallback on earlier versions
                        if let texture = self.textures?[metallicRoughnessTextureInfo.index] {
                            
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
                TextureStorageManager.manager.loadTexture(gltf:self, index: normalTextureInfo.index!, property: scnMaterial.normal)
            }
            
            if let occlusionTextureInfo = material.occlusionTexture {
                TextureStorageManager.manager.loadTexture(gltf:self, index: occlusionTextureInfo.index!, property: scnMaterial.ambientOcclusion)
                scnMaterial.ambientOcclusion.intensity = CGFloat(occlusionTextureInfo.strength)
            }
            
            if let emissiveTextureInfo = material.emissiveTexture {
                TextureStorageManager.manager.loadTexture(gltf:self, index: emissiveTextureInfo.index, property: scnMaterial.emission)
            } else {
                let color = (material.emissiveFactor.count < 3) ? [1, 1, 1] : (material.emissiveFactor)
                scnMaterial.emission.contents = SCNVector4Make(SCNFloat(color[0]), SCNFloat(color[1]), SCNFloat(color[2]), 1.0)
            }
            
            completionHandler(scnMaterial)
        } else {
            completionHandler(SCNMaterial())
        }        
    }
    
    // get image by index
    fileprivate func image(byIndex index:Int) -> OSImage? {
        if let gltf_image = self.images?[index] {
            if let image = try? self.loader.load(resource: gltf_image) {
                return image
            }
        }
        return nil
    }
        
    fileprivate func loadSampler(sampler samplerIndex:Int?, property:SCNMaterialProperty) {
        if let sampler = self.samplers?[samplerIndex!] {
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
