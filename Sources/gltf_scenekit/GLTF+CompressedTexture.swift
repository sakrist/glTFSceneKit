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
            
            var width = descriptor.width
            var height = descriptor.height
            
            let (bytesPerRow, pixelFormat) = _get_bpp_pixelFormat(descriptor)
            
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
                let bufferViewIndex = descriptor.sources[i]
                if let (_, data) = try? requestData(bufferView: bufferViewIndex) {
                    let bPr = bytesPerRow(width, height)
                    data.withUnsafeBytes {
                        texture?.replace(region: MTLRegionMake2D(0, 0, width, height), 
                                         mipmapLevel: i, 
                                         withBytes: $0, 
                                         bytesPerRow: bPr)
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
    
    fileprivate func _get_bpp_pixelFormat(_ descriptor:GLTF_3D4MCompressedTextureExtension) ->((Int, Int)->Int,  MTLPixelFormat) {
        var bytesPerRow:(Int, Int)->Int = {_,_ in return 0 }
        var pixelFormat:MTLPixelFormat = .invalid;
        
        
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
        #elseif os(iOS)
        
        switch descriptor.compression {
        case .ETC1_RGB8_OES:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_RGB8_ETC2:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_ETC2:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_RGBA8_ETC2_EAC:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:
            assert(false, " \(descriptor.compression) not supported yet")
            break
        case .COMPRESSED_SRGB_PVRTC_2BPPV1:
            pixelFormat = .pvrtc_rgb_2bpp_srgb
            break
        case .COMPRESSED_SRGB_PVRTC_4BPPV1:
            pixelFormat = .pvrtc_rgb_4bpp_srgb
            break
        case .COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1:
            pixelFormat = .pvrtc_rgba_2bpp_srgb
            break
        case .COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1:
            pixelFormat = .pvrtc_rgba_4bpp_srgb
            break
        case .COMPRESSED_RGB_PVRTC_4BPPV1:
            pixelFormat = .pvrtc_rgb_4bpp
            break
        case .COMPRESSED_RGB_PVRTC_2BPPV1:
            pixelFormat = .pvrtc_rgb_2bpp
            break
        case .COMPRESSED_RGBA_PVRTC_4BPPV1:
            pixelFormat = .pvrtc_rgba_4bpp
            break
        case .COMPRESSED_RGBA_PVRTC_2BPPV1:
            pixelFormat = .pvrtc_rgba_2bpp
            break
        case .COMPRESSED_RGBA_ASTC_4x4:
            pixelFormat = .astc_4x4_ldr
            bytesPerRow = {width, height in return (width + 4 - 1) / 4 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_5x4:
            pixelFormat = .astc_5x4_ldr
            bytesPerRow = {width, height in return (width + 5 - 1) / 5 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_5x5:
            pixelFormat = .astc_5x5_ldr
            bytesPerRow = {width, height in return (width + 5 - 1) / 5 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_6x5:
            pixelFormat = .astc_6x5_ldr
            bytesPerRow = {width, height in return (width + 6 - 1) / 6 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_6x6:
            pixelFormat = .astc_6x6_ldr
            bytesPerRow = {width, height in return (width + 6 - 1) / 6 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_8x5:
            pixelFormat = .astc_8x5_ldr
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_8x6:
            pixelFormat = .astc_8x6_ldr
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_8x8:
            pixelFormat = .astc_8x8_ldr
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_10x5:
            pixelFormat = .astc_10x5_ldr
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_10x6:
            pixelFormat = .astc_10x6_ldr
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_10x8:
            pixelFormat = .astc_10x8_ldr
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_10x10:
            pixelFormat = .astc_10x10_ldr
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_12x10:
            pixelFormat = .astc_12x10_ldr
            bytesPerRow = {width, height in return (width + 12 - 1) / 12 * 16 };
            break
        case .COMPRESSED_RGBA_ASTC_12x12:
            pixelFormat = .astc_12x12_ldr
            bytesPerRow = {width, height in return (width + 12 - 1) / 12 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_4x4:
            pixelFormat = .astc_4x4_srgb
            bytesPerRow = {width, height in return (width + 4 - 1) / 4 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_5x4:
            pixelFormat = .astc_5x4_srgb
            bytesPerRow = {width, height in return (width + 5 - 1) / 5 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_5x5:
            pixelFormat = .astc_5x5_srgb
            bytesPerRow = {width, height in return (width + 5 - 1) / 5 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_6x5:
            pixelFormat = .astc_6x5_srgb
            bytesPerRow = {width, height in return (width + 6 - 1) / 6 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_6x6:
            pixelFormat = .astc_6x6_srgb
            bytesPerRow = {width, height in return (width + 6 - 1) / 6 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x5:
            pixelFormat = .astc_8x5_srgb
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x6:
            pixelFormat = .astc_8x6_srgb
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x8:
            pixelFormat = .astc_8x8_srgb
            bytesPerRow = {width, height in return (width + 8 - 1) / 8 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x5:
            pixelFormat = .astc_10x5_srgb
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x6:
            pixelFormat = .astc_10x6_srgb
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x8:
            pixelFormat = .astc_10x8_srgb
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x10:
            pixelFormat = .astc_10x10_srgb
            bytesPerRow = {width, height in return (width + 10 - 1) / 10 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_12x10:
            pixelFormat = .astc_12x10_srgb
            bytesPerRow = {width, height in return (width + 12 - 1) / 12 * 16 };
            break
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_12x12:
            pixelFormat = .astc_12x12_srgb
            bytesPerRow = {width, height in return (width + 12 - 1) / 12 * 16 };
            break
            
        default:
            assert(false, " \(descriptor.compression) can't bbe supported on iOS")
            break
        }
        
        #endif
        return (bytesPerRow, pixelFormat)
    } 
    
}
