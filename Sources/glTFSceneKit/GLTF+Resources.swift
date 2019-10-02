//
//  GLTF+Resources.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation


/// Description for resources delivery by request from general GLTF converter. 
/// - Simple implementation is GLTFResourceLoaderDefault and utilised as default resource delivery instrument.
/// - Optionaly can be implemented own resource loader, for example if requered to deliver content from remote server.
/// - All functionas with completion handler considered as possible delayed delivery, i.e. multi-thread or work with network.
public protocol GLTFResourceLoader {
    
    /// Set location where is gltf file is located.
    var directoryPath: String { get set }
    
    func load(gltf: GLTF, resource: GLTFBuffer) throws -> Data?
    func load(gltf: GLTF, resource: GLTFBuffer, completionHandler: @escaping (GLTFBuffer, Error?) -> Void )
    func load(gltf: GLTF, resources: Set<GLTFBuffer>, completionHandler: @escaping (Error?) -> Void )
    
    func load(gltf: GLTF, resource: GLTFImage) throws -> OSImage?
    func load(gltf: GLTF, resource: GLTFImage, completionHandler: @escaping (GLTFImage, Error?) -> Void )
    
    /// This function going to be call if `cancel` was occured on GLTF convert.
    func cancelAll()
} 

extension GLTF {
    public var loader:GLTFResourceLoader {
        get {
            var loader_ = objc_getAssociatedObject(self, &Keys.resource_loader) as? GLTFResourceLoader
            if loader_ != nil {
                return loader_!
            }
            loader_ = GLTFResourceLoaderDefault()
            self.loader = loader_!
            return loader_!
        }
        set { objc_setAssociatedObject(self, &Keys.resource_loader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}


/// Default resource delivery instrument.
open class GLTFResourceLoaderDefault : GLTFResourceLoader {
    
    public var directoryPath: String = ""
    
    public init() {}
    
    open func load(gltf: GLTF, resource: GLTFBuffer) throws -> Data? {
        if resource.data == nil && resource.uri != nil {
            resource.data = try loadUri(uri: resource.uri!)
        }
        return resource.data
    }
    
    open func load(gltf: GLTF, resource: GLTFBuffer, completionHandler: @escaping (GLTFBuffer, Error?) -> Void) {
        var error_:Error?
        do {
            if resource.data == nil && resource.uri != nil {
                if let data = try loadUri(uri: resource.uri!) {
                    resource.data = data 
                }
            }
        } catch {
            error_ = error
        }
        completionHandler(resource, error_)
    }
    
    open func load(gltf: GLTF, resources: Set<GLTFBuffer>, completionHandler: @escaping (Error?) -> Void) {
        var error_:Error?
        do {
            for resource in resources {
                if resource.data == nil && resource.uri != nil {
                    if let data = try loadUri(uri: resource.uri!) {
                        resource.data = data 
                    }
                }
            }
        } catch {
            error_ = error
        }
        DispatchQueue.global().async {
            completionHandler(error_)   
        }
        
    }
    
    open func load(gltf: GLTF, resource: GLTFImage) throws -> OSImage? {
        if resource.image == nil && resource.uri != nil {
            if let imageData = try loadUri(uri: resource.uri!) {
                resource.image = OSImage.init(data: imageData)
            }
        }
        return resource.image
    }
    
    open func load(gltf: GLTF, resource: GLTFImage, completionHandler: @escaping (GLTFImage, Error?) -> Void) {
        var error_:Error?
        do {
            if resource.image == nil && resource.uri != nil {
                if let imageData = try loadUri(uri: resource.uri!) {
                        resource.image = OSImage.init(data: imageData)                
                }
            }
        } catch {
            error_ = error
        }
        completionHandler(resource, error_)
    }
    
    open func cancelAll() {
        
    }
    
    fileprivate func loadUri(uri: String) throws -> Data? {
        var data = uri.base64Decoded()
        if data == nil {
            
            if (uri.hasPrefix("http")) {
                if let url = URL.init(string: uri) {
                    data = try Data.init(contentsOf: url)
                    return data
                }
            }
            
            let filepath = [self.directoryPath, uri].joined(separator: "/")
            let url = URL(fileURLWithPath: filepath)
            data = try Data.init(contentsOf: url)
        } else {
            return (data == nil) ? nil : Data([UInt8](data!))
        }
        return data
    }    
}




extension GLTFBuffer {
    
    static var data_associate_key = "data_associate_key"
    
    public var data:Data? {
        get { return objc_getAssociatedObject(self, &GLTFBuffer.data_associate_key) as? Data }
        set { objc_setAssociatedObject(self, &GLTFBuffer.data_associate_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

extension GLTFImage {
    
    static var image_associate_key = "image_associate_key"
    
    public var image:OSImage? {
        get { return objc_getAssociatedObject(self, &GLTFImage.image_associate_key) as? OSImage }
        set { objc_setAssociatedObject(self, &GLTFImage.image_associate_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
