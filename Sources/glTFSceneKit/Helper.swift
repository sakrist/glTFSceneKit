//
//  Helper.swift
//  
//
//  Created by Volodymyr Boichentsov on 12/10/2017.
//  Copyright © 2017 Volodymyr Boichentsov. All rights reserved.
//

import Foundation
import SceneKit

#if os(iOS)
    public typealias OSImage = UIImage
    public typealias OSColor = UIColor
    typealias SCNFloat = Float
#elseif os(macOS)
    public typealias OSImage = NSImage
    public typealias OSColor = NSColor
    typealias SCNFloat = CGFloat
#endif


struct SCNVector2 {
    public var x: SCNFloat
    public var y: SCNFloat
    public init() {
        x = 0
        y = 0
    }
    public init(x: SCNFloat, y: SCNFloat) {
        self.x = x
        self.y = y  
    } 
}


extension String: Error {}

extension SCNMatrix4 {
    init(array:[Double]) {
        self.init()
        self.m11 = SCNFloat(array[0])
        self.m12 = SCNFloat(array[1])
        self.m13 = SCNFloat(array[2])
        self.m14 = SCNFloat(array[3])
        self.m21 = SCNFloat(array[4])
        self.m22 = SCNFloat(array[5])
        self.m23 = SCNFloat(array[6])
        self.m24 = SCNFloat(array[7])
        self.m31 = SCNFloat(array[8])
        self.m32 = SCNFloat(array[9])
        self.m33 = SCNFloat(array[10])
        self.m34 = SCNFloat(array[11])
        self.m41 = SCNFloat(array[12])
        self.m42 = SCNFloat(array[13])
        self.m43 = SCNFloat(array[14])
        self.m44 = SCNFloat(array[15])
    }
}

extension String {
    //: ### Base64 encoding a string
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    //: ### Base64 decoding a string
    func base64Decoded() -> Data? {
        if self.contains("base64") {
            do {
                let data = try Data(contentsOf: URL(string: self)!)
                return data
            } catch {}
        }
        return nil
    }
}

extension Data {
    var int8: Int8 {
        return withUnsafeBytes { $0.pointee }
    }
    var uint8: UInt8 {
        return withUnsafeBytes { $0.pointee }
    }
    var int16: Int16 {
        return withUnsafeBytes { $0.pointee }
    }
    var uint16: UInt16 {
        return withUnsafeBytes { $0.pointee }
    }
    var int32: Int32 {
        return withUnsafeBytes { $0.pointee }
    }
    var uint32: UInt32 {
        return withUnsafeBytes { $0.pointee }
    }
    var integer: Int {
        return withUnsafeBytes { $0.pointee }
    }
    var uinteger: UInt {
        return withUnsafeBytes { $0.pointee }
    }
    var float: Float {
        return withUnsafeBytes { $0.pointee }
    }
    var double: Double {
        return withUnsafeBytes { $0.pointee }
    }
    var vec2: SCNVector2 {
        return withUnsafeBytes { $0.pointee }
    }
    var vec3: SCNVector3 {
        return withUnsafeBytes { $0.pointee }
    }
    var vec4: SCNVector4 {
        return withUnsafeBytes { $0.pointee }
    }
    var int8Array: [Int8] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<Int8>(start: $0, count: self.count/MemoryLayout<Int8>.size)) 
        }
    }
    var uint8Array: [UInt8] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<UInt8>(start: $0, count: self.count/MemoryLayout<UInt8>.size)) 
        }
    }
    var int16Array: [Int16] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<Int16>(start: $0, count: self.count/MemoryLayout<Int16>.size)) 
        }
    }
    var uint16Array: [UInt16] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<UInt16>(start: $0, count: self.count/MemoryLayout<UInt16>.size)) 
        }
    }
    var int32Array: [Int32] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<Int32>(start: $0, count: self.count/MemoryLayout<Int32>.size)) 
        }
    }
    var uint32Array: [UInt32] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<UInt32>(start: $0, count: self.count/MemoryLayout<UInt32>.size)) 
        }
    }
    var floatArray: [Float] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<Float>(start: $0, count: self.count/MemoryLayout<Float>.size)) 
        }
    }
    var vec2Array: [GLKVector2] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<GLKVector2>(start: $0, count: self.count/MemoryLayout<GLKVector2>.size)) 
        }
    }
    var vec3Array: [GLKVector3] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<GLKVector3>(start: $0, count: self.count/MemoryLayout<GLKVector3>.size)) 
        }
    }
    var vec4Array: [GLKVector4] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<GLKVector4>(start: $0, count: self.count/MemoryLayout<GLKVector4>.size)) 
        }
    }
    var mat4Array: [GLKMatrix4] {
        return withUnsafeBytes { 
            Array(UnsafeBufferPointer<GLKMatrix4>(start: $0, count: self.count/MemoryLayout<GLKMatrix4>.size)) 
        }
    }
}

// Code reference to here
// https://github.com/magicien/GLTFSceneKit/blob/master/Source/Common/GLTFFunctions.swift

extension OSImage {
    
    func channels() throws -> [OSImage] {
        #if os(macOS)
            var rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
            guard let cgImage = self.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                throw "Failed to create CGImage"
            }
        #else
            guard let cgImage = self.cgImage else {
                throw "failed to create CGImage"
            }
        #endif
        return try channels(from: cgImage)
    }
    
    
    func channels(from image: CGImage) throws -> [OSImage] {
        let w = image.width
        let h = image.height
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let bitsPerComponent = image.bitsPerComponent
        let componentsPerPixel = image.bitsPerPixel / bitsPerComponent
        let srcBytesPerPixel = image.bitsPerPixel / 8
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let srcDataSize = w * h * srcBytesPerPixel
        let rawPtr: UnsafeMutableRawPointer = malloc(srcDataSize)
        defer { free(rawPtr) }
        
        
        guard let context = CGContext(data: rawPtr, width: w, height: h, bitsPerComponent: bitsPerComponent, bytesPerRow: srcBytesPerPixel * w, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
            throw "Failed to make textures"
        }
        context.draw(image, in: rect)
        
        let ptr = rawPtr.bindMemory(to: UInt8.self, capacity: srcDataSize)
        
        /// create data for each component
        let dstBytesPerPixel = bitsPerComponent / 8
        let dstDataSize = w * h * dstBytesPerPixel
        
        var componentsRaw:[UnsafeMutableRawPointer] = [UnsafeMutableRawPointer]()
        var componentsPtr = [Any]()
        
        for _ in 0..<componentsPerPixel {
            let componentRawPtr: UnsafeMutableRawPointer = malloc(dstDataSize)
            let componentPtr = componentRawPtr.bindMemory(to: UInt8.self, capacity: dstDataSize)
            componentsRaw.append(componentRawPtr)
            componentsPtr.append(componentPtr)
        }
        
        var srcPos = 0
        var dstPos = 0
        for _ in 0..<(w * h) {
            var i = 0
            for component in componentsPtr {
                let componentPtr = component as! UnsafeMutablePointer<UInt8>
                componentPtr[dstPos] = ptr[srcPos + i]
                i += 1
            }
            srcPos += srcBytesPerPixel
            dstPos += dstBytesPerPixel
        }
        let dstColorSpace = CGColorSpaceCreateDeviceGray()
        
        var images = [OSImage]()
        
        for i in 0..<componentsPerPixel {
            let componentPtr = componentsPtr[i] as! UnsafeMutablePointer<UInt8>
            
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            guard let imageData = CFDataCreate(nil, componentPtr, dstDataSize) else {
                throw "Failed to create Data"
            }
            guard let provider = CGDataProvider(data: imageData) else {
                throw "Failed to create Provider"
            }
            guard let imageChannel = CGImage(
                width: w, height: h,
                bitsPerComponent: bitsPerComponent,
                bitsPerPixel: bitsPerComponent,
                bytesPerRow: w * dstBytesPerPixel,
                space: dstColorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: CGColorRenderingIntent.defaultIntent) else {
                    throw "Failed to create CGImage"
            }
            #if os(macOS)
                let image_ = OSImage(cgImage: imageChannel, size: NSSize.init(width: w, height: h))
            #else
                let image_ = OSImage(cgImage: imageChannel)
            #endif
            images.append(image_)
        }
        for c in componentsRaw {
            free(c)
        }
        componentsRaw.removeAll()
        componentsPtr.removeAll()
        
        return images
    }
    
}


extension MTLPixelFormat {
    public func hasAlpha() -> Bool {
        switch self {
        case .rgba8Unorm, .rgba8Unorm_srgb, .rgba8Snorm, .rgba8Uint, .rgba8Sint,
            .bgra8Unorm, .bgra8Unorm_srgb, .rgb10a2Unorm, .rgb10a2Uint, .bgr10a2Unorm,
            .rgba16Unorm, .rgba16Snorm, .rgba16Uint, .rgba16Sint, .rgba16Float, .rgba32Uint,
            .rgba32Sint, .rgba32Float, .bc1_rgba, .bc1_rgba_srgb, .bc2_rgba, .bc2_rgba_srgb,
            .bc3_rgba, .bc3_rgba_srgb, .bc7_rgbaUnorm, .bc7_rgbaUnorm_srgb:
            return true
        default:
            return false
        }
    }
}

extension SCNMaterial {
    public func hasAlpha() -> Bool {
        return (diffuse.contents as? MTLTexture)?.pixelFormat.hasAlpha() ?? false
    }
}



