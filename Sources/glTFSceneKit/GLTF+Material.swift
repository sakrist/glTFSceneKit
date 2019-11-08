//
//  GLTF+Material.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation
import SceneKit


extension GLTF {
    
    // MARK: - Material
    
    // load material by index
    internal func loadMaterial(index:Int, delegate: TextureLoaderDelegate, textureChangedCallback: ((Any?)-> Void)? = nil, completionHandler: @escaping (SCNMaterial) -> Void) {
        
        if let material = self.materials?[index] {
            let scnMaterial = SCNMaterial()
            scnMaterial.name = material.name
            scnMaterial.isDoubleSided = material.doubleSided
            
            if let pbr = material.pbrMetallicRoughness {
                
                // set PBR type
                scnMaterial.lightingModel = .physicallyBased
                
                if let baseTextureInfo = pbr.baseColorTexture {
                    TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index:baseTextureInfo.index, property: scnMaterial.diffuse)
                } else {
                    let color = (pbr.baseColorFactor.count < 4) ? [1, 1, 1, 1] : (pbr.baseColorFactor)
                    scnMaterial.diffuse.contents = OSColor(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: CGFloat(color[3]))
                }
               
                // transparency/opacity
                scnMaterial.transparency = CGFloat(pbr.baseColorFactor[3])
                
                if let metallicRoughnessTextureInfo = pbr.metallicRoughnessTexture {
                    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, *) {
                        scnMaterial.metalness.textureComponents = .blue
                        scnMaterial.roughness.textureComponents = .green
                        TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index:metallicRoughnessTextureInfo.index, property: scnMaterial.metalness)
                        TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index:metallicRoughnessTextureInfo.index, property: scnMaterial.roughness)
                    } else {
                        // Fallback on earlier versions
                        if let texture = self.textures?[metallicRoughnessTextureInfo.index] {
                            
                            if texture.source != nil {
                                
                                loadSampler(sampler:texture.sampler, property: scnMaterial.roughness)
                                loadSampler(sampler:texture.sampler, property: scnMaterial.metalness)
                                
                                let image = self.image(byIndex:texture.source!)
                                if let images = ((try? image?.channels()) as [OSImage]??) {
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
                TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index: normalTextureInfo.index!, property: scnMaterial.normal)
            }
            
            if let occlusionTextureInfo = material.occlusionTexture {
                TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index: occlusionTextureInfo.index!, property: scnMaterial.ambientOcclusion)
                scnMaterial.ambientOcclusion.intensity = CGFloat(occlusionTextureInfo.strength)
            }
            
            if let emissiveTextureInfo = material.emissiveTexture {
                TextureStorageManager.loadTexture(gltf:self, delegate: delegate, index: emissiveTextureInfo.index, property: scnMaterial.emission)
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
            if let image = ((try? self.loader.load(gltf:self, resource: gltf_image)) as OSImage??) {
                return image
            }
        }
        return nil
    }
        
    func loadSampler(sampler samplerIndex:Int?, property:SCNMaterialProperty) {
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

