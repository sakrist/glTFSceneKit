//
//  GLTF+texture.swift
//  gltf_scenekitPackageDescription
//
//  Created by Volodymyr Boichentsov on 06/04/2018.
//

import Foundation
import SceneKit

extension GLTF {
    
    func createCompressedTexture(_ descriptor:GLTF_3D4MCompressedTextureExtension) -> Any? {
        
        if self.view?.renderingAPI == .metal {
            
            var bytesPerRow:(Int, Int)->Int = {_,_ in return 0 }
            var pixelFormat:MTLPixelFormat = .invalid;
            var width = descriptor.width;
            var height = descriptor.height;
            
            #if os(macOS)
            if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT1) {
                pixelFormat = .bc1_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT1) {
                pixelFormat = .bc1_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT3) {
                pixelFormat = .bc2_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT3) {
                pixelFormat = .bc2_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT5) {
                pixelFormat = .bc3_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT5) {
                pixelFormat = .bc3_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_BPTC_UNORM) {
                pixelFormat = .bc7_rgbaUnorm
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_BPTC_UNORM) {
                pixelFormat = .bc7_rgbaUnorm_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            }
            #endif
            
            if (pixelFormat == .invalid ) {
                print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, unsupported compression format \(descriptor.compression).")
                return nil
            }
            
            if (width == 0 || height == 0) {
                print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, inappropriate texture size.")
                return nil
            }
            
            let mipmapsCount = descriptor.sources.count
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, 
                                                                             width: width, 
                                                                             height: height, 
                                                                             mipmapped: (mipmapsCount > 1))
            textureDescriptor.mipmapLevelCount = mipmapsCount
            
            var device:MTLDevice?
            #if os(macOS)
            device = self.view?.device
            #endif            
            if (device == nil) {
                device = MTLCreateSystemDefaultDevice()
            }
            
            let texture = device?.makeTexture(descriptor: textureDescriptor)
            
            for i in 0 ..< mipmapsCount {
                let bufferViewsIndex = descriptor.sources[i]
                if self.bufferViews!.count > bufferViewsIndex {
                    let bufferView = self.bufferViews![bufferViewsIndex]
                    let buffer = self.buffers![bufferView.buffer]
                    let data = buffer.data(inDirectory: self.directory, cache: false)
                    if (data == nil) {
                        print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, \(String(describing: buffer.uri))")
                        return nil
                    }
                    data?.withUnsafeBytes {
                        texture?.replace(region: MTLRegionMake2D(0, 0, width, height), 
                                         mipmapLevel: i, 
                                         withBytes: $0, 
                                         bytesPerRow: bytesPerRow(width, height))
                    }
                }
                
                width = max(width >> 1, 1);
                height = max(height >> 1, 1);
            }
            return texture 
        } else {
            // TODO: implement for OpenGL  
            // Use GLKTextureInfo
        }
        
        return nil
    }
}
