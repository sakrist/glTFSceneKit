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

protocol TextureLoaderDelegate {
    var renderer: SCNSceneRenderer? { get }
    var isCancelled: Bool { get }
    func texturesLoaded()
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
                    property.contents = self.content_
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
        property.contents = self.content
    }
    
    deinit {
        associatedProperties.removeAll()
    }
}

class TextureStorageManager {
    
    static let manager = TextureStorageManager()
    
    private var worker = DispatchQueue(label: "textures_loader")
    private var groups:[Int : DispatchGroup] = [Int : DispatchGroup]()
    
    lazy private var _associators:[Int : [Int : TextureAssociator]] = [Int : [Int : TextureAssociator]]()
    
    func clear(gltf: GLTF) {
        let hash = gltf.hashValue
        self.groups[hash] = nil
        self._associators[hash] = nil
    }
    
    func textureAssociator(gltf: GLTF, at index: Int) -> TextureAssociator {
        let hash = gltf.hashValue
        
        if self._associators[hash] == nil {
           self._associators[hash] = [Int : TextureAssociator]()
        }
        var tStatus = (self._associators[hash])![index] 
        if tStatus == nil {
            tStatus = TextureAssociator()
            self._associators[hash]![index] = tStatus
        }
        return tStatus!
    }
    
    func group(gltf: GLTF, delegate: TextureLoaderDelegate, _ enter:Bool = false) -> DispatchGroup {
        let index = gltf.hashValue
        var group: DispatchGroup? = groups[index]
        
        if group == nil {
            groups[index] = DispatchGroup()
            group = groups[index]
            group?.enter()
            
            let startLoadTextures = Date()
            
            // notify when all textures are loaded
            // this is last operation.
            group?.notify(queue: DispatchQueue.main) {
                
                os_log("textures loaded %d ms", log: log_scenekit, type: .debug, Int(startLoadTextures.timeIntervalSinceNow * -1000))
                
                delegate.texturesLoaded()
            }
            
        } else if enter {
            group?.enter()
        }
        return group!
    }
    
    
    /// Load texture by index.
    ///
    /// - Parameters:
    ///   - index: index of GLTFTexture in textures
    ///   - property: material's property
    static func loadTexture(gltf: GLTF, delegate: TextureLoaderDelegate, index: Int, property: SCNMaterialProperty, callback: ((Any?)-> Void)? = nil) {
        self.manager._loadTexture(gltf: gltf, delegate: delegate, index: index, property: property, callback: callback)
    }
    
    fileprivate func _loadTexture(gltf: GLTF, delegate: TextureLoaderDelegate, index: Int, property: SCNMaterialProperty, callback: ((Any?)-> Void)? = nil) {
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
                let metalOn = (delegate.renderer?.renderingAPI == .metal || device != nil)
                
                if let descriptor = texture.extensions?[compressedTextureExtensionKey] as? GLTF_3D4MCompressedTextureExtension, metalOn {
                    
                    let group = self.group(gltf:gltf, delegate: delegate, true) 
                    
                    // load first level mipmap as texture
                    gltf.loadCompressedTexture(descriptor:descriptor, loadLevel: .first) { cTexture, error in        
                        
                        if delegate.isCancelled {
                            group.leave()
                            return
                        }
                        
                        if (error != nil) {
                            print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                            self._loadImageTexture(gltf, delegate, texture, tStatus, callback)
                            group.leave()
                        } else {
                            tStatus.content = cTexture as Any?
                            callback?(cTexture)
                            
                            // load all levels
                            gltf.loadCompressedTexture(descriptor:descriptor, loadLevel: .last) { (cTexture2, error) in
                                
                                if delegate.isCancelled {
                                    group.leave()
                                    return
                                }
                                
                                if (error != nil) {
                                    print("Failed to load comressed texture \(error.debugDescription). Fallback on image source.")
                                    self._loadImageTexture(gltf, delegate, texture, tStatus, callback)
                                } else {
                                    tStatus.content = cTexture2 as Any?
                                    callback?(cTexture2)
                                }
                                group.leave()
                            }
                        }
                    }
                } else {
                    self._loadImageTexture(gltf, delegate, texture, tStatus, callback)
                }
            } else {
                tStatus.associate(property: property)
            }
        }
    }
    
    /// load original image source png or jpg
    fileprivate func _loadImageTexture(_ gltf: GLTF, _ delegate: TextureLoaderDelegate, _ texture: GLTFTexture, _ tStatus: TextureAssociator, _ callback: ((Any?)-> Void)? = nil) {
        self.worker.async {
            if delegate.isCancelled {
                return
            }
            let group = self.group(gltf:gltf, delegate: delegate, true)
            
            if let imageSourceIndex = texture.source {
                if let gltf_image = gltf.images?[imageSourceIndex] {
                    
                    gltf.loader.load(gltf:gltf, resource: gltf_image) { resource, error in
                        if resource.image != nil {
                            tStatus.content = gltf._compress(image:resource.image!)
                            callback?(tStatus.content)
                        }
                        group.leave()
                    }
                }
            }
        }
    }
}

