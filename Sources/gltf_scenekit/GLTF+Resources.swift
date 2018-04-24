//
//  GLTF+Resources.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation


protocol GLTFResourceLoader {
    
    // location where is gltf file is located.
    var directoryPath: String { get set }
    
    func load(resource: GLTFBuffer) throws -> Data?
    func load(resource: GLTFBuffer, completionHandler: @escaping (GLTFBuffer) -> Void )
    func load(resources: [GLTFBuffer], completionHandler: @escaping () -> Void )
    
    func load(resource: GLTFImage) throws -> ImageClass?
    func load(resource: GLTFImage, completionHandler: @escaping (GLTFImage) -> Void )
} 

extension GLTF {
    var loader:GLTFResourceLoader {
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


class GLTFResourceLoaderDefault : GLTFResourceLoader {
    
    var directoryPath: String = ""
    
    func load(resource: GLTFBuffer) throws -> Data? {
        if resource.data == nil && resource.uri != nil {
            resource.data = try loadUri(uri: resource.uri!)
        }
        return resource.data
    }
    
    func load(resource: GLTFBuffer, completionHandler: @escaping (GLTFBuffer) -> Void) {
        
    }
    
    func load(resources: [GLTFBuffer], completionHandler: @escaping () -> Void) {
        
    }
    
    func load(resource: GLTFImage) throws -> ImageClass? {
        if resource.image == nil && resource.uri != nil {
            if let imageData = try loadUri(uri: resource.uri!) {
                resource.image = ImageClass.init(data: imageData)
            }
        }
        return resource.image
    }
    
    func load(resource: GLTFImage, completionHandler: @escaping (GLTFImage) -> Void) {
        
    }
    
    fileprivate func loadUri(uri: String) throws -> Data? {
        var data = uri.base64Decoded()
        if data == nil {
            
            if (uri.contains("http")) {
                if let url = URL.init(string: uri) {
                    data = try Data.init(contentsOf: url)
                    return data
                }
            }
            
            let filepath = [self.directoryPath, uri].joined(separator: "/") 
            if FileManager.default.fileExists(atPath: filepath) {
                let url = URL(fileURLWithPath: filepath)
                do {
                    data = try Data.init(contentsOf: url)
                } catch {
                    throw "Can't load file at \(url) \(error)"
                }
            } else {
                throw "Can't find file at \(filepath)"
            }
        } else {
            return (data == nil) ? nil : Data(bytes: [UInt8](data!))
        }
        return data
    }    
}




extension GLTFBuffer {
    
    static var data_associate_key = "data_associate_key"
    
    var data:Data? {
        get { return objc_getAssociatedObject(self, &GLTFBuffer.data_associate_key) as? Data }
        set { objc_setAssociatedObject(self, &GLTFBuffer.data_associate_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

extension GLTFImage {
    
    static var image_associate_key = "image_associate_key"
    
    var image:ImageClass? {
        get { return objc_getAssociatedObject(self, &GLTFImage.image_associate_key) as? ImageClass }
        set { objc_setAssociatedObject(self, &GLTFImage.image_associate_key, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
