//
//  TextureStorageManager.swift
//  glTFSceneKit
//
//  Created by Volodymyr Boichentsov on 29/04/2018.
//

import Foundation
import SceneKit
import os

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
    private var groups:[Int : DispatchGroup] = [Int : DispatchGroup]()
    
    lazy private var _associators:[Int : [Int : TextureAssociator]] = [Int : [Int : TextureAssociator]]()
    
    private var lock = os_unfair_lock_s()
    private var glock = os_unfair_lock_s()
    
    func textureAssociator(gltf: GLTF, at index: Int) -> TextureAssociator {

        os_unfair_lock_lock(&lock)
        if _associators[gltf.hashValue] == nil {
           _associators[gltf.hashValue] = [Int : TextureAssociator]()
        }
        var tStatus = (_associators[gltf.hashValue])![index] 
        if tStatus == nil {
            tStatus = TextureAssociator()
            _associators[gltf.hashValue]![index] = tStatus
        }
        os_unfair_lock_unlock(&lock)
        return tStatus!
    }
    
    func group(gltf: GLTF, _ enter:Bool = false) -> DispatchGroup {
        let index = gltf.hashValue
        var group:DispatchGroup?
        os_unfair_lock_lock(&glock)
        group = groups[index]
        if group == nil {
            groups[index] = DispatchGroup()
            group = groups[index]
            group?.enter()
            
            let startLoadTextures = Date()
            
            // notify when all textures are loaded
            // this is last operation.
            group?.notify(queue: DispatchQueue.main) {
                
                os_log("textures loaded %d ms", log: log_scenekit, type: .debug, Int(startLoadTextures.timeIntervalSinceNow * -1000))
                
                self.groups[index] = nil
                self._associators[index] = nil
                gltf._converted()
            }
            
        } else if enter {
            group?.enter()
        }
        os_unfair_lock_unlock(&glock)
        return group!
    }
    
    
    /// Load texture by index.
    ///
    /// - Parameters:
    ///   - index: index of GLTFTexture in textures
    ///   - property: material's property
    static func loadTexture(gltf: GLTF, index: Int, property: SCNMaterialProperty) {
        self.manager._loadTexture(gltf: gltf, index: index, property: property)
    }
    
    fileprivate func _loadTexture(gltf: GLTF, index: Int, property: SCNMaterialProperty) {
        guard let texture = gltf.textures?[index] else {
            print("Failed to find texture")
            return
        } 
        
        worker.async {
            let tStatus = self.textureAssociator(gltf:gltf, at:index)
            
            if tStatus.status == .no {
                tStatus.status = .loading
                tStatus.associate(property: property)
                
                gltf.loadSampler(sampler:texture.sampler, property: property)
                
                let device = MTLCreateSystemDefaultDevice()
                let metalOn = (gltf.renderer?.renderingAPI == .metal || device != nil)
                
                if let descriptor = texture.extensions?[compressedTextureExtensionKey], metalOn {
                    
                    let group = self.group(gltf:gltf, true) 
                    
                    // load first level mipmap as texture
                    gltf.loadCompressedTexture(descriptor:descriptor as! GLTF_3D4MCompressedTextureExtension, loadLevel: .first) { cTexture, error in        
                        
                        if gltf.isCanceled {
                            group.leave()
                            return
                        }
                        
                        if (error != nil) {
                            print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                            self._loadImageTexture(gltf, texture, tStatus)
                            group.leave()
                        } else {
                            tStatus.content = cTexture as Any?
                            
                            // load all levels
                            gltf.loadCompressedTexture(descriptor:descriptor as! GLTF_3D4MCompressedTextureExtension, loadLevel: .all) { (cTexture2, error) in
                                
                                if gltf.isCanceled {
                                    group.leave()
                                    return
                                }
                                
                                if (error != nil) {
                                    print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                                    self._loadImageTexture(gltf, texture, tStatus)
                                } else {
                                    tStatus.content = cTexture2 as Any?
                                }
                                group.leave()
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
    fileprivate func _loadImageTexture(_ gltf: GLTF, _ texture: GLTFTexture, _ tStatus: TextureAssociator) {
        DispatchQueue.global().async {
            if gltf.isCanceled {
                return
            }
            let group = self.group(gltf:gltf, true) 
            
            var textureResult:OSImage?
            if let imageSourceIndex = texture.source {
                if let gltf_image = gltf.images?[imageSourceIndex] {
                    do {
                        textureResult = try gltf.loader.load(gltf:gltf, resource: gltf_image)
                    } catch {
                        print("Failed to load image. \(error)")
                        group.leave()
                    }
                }
            }
            if textureResult != nil {
                tStatus.content = gltf._compress(image:textureResult!)
                group.leave()
            }
        }
    }
}

