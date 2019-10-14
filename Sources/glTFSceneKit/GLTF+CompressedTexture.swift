//
//  GLTF+texture.swift
//  gltf_scenekitPackageDescription
//
//  Created by Volodymyr Boichentsov on 06/04/2018.
//

import Foundation
import SceneKit

enum CTLevel:Int {
    case first = 0
    case last
    case all
}
extension GLTF {
    
    func loadCompressedTexture(descriptor:GLTF_3D4MCompressedTextureExtension, loadLevel:CTLevel, completionHandler: @escaping (Any?, Error?) -> Void ) {
        
        let width = descriptor.width
        let height = descriptor.height
        
        if (width == 0 || height == 0) {
            completionHandler(nil, GLTFError("GLTF_3D4MCompressedTextureExtension: Failed to load texture, inappropriate texture size."))
            return
        }
        
        let (bytesPerRow, pixelFormat) = _get_bpp_pixelFormat(descriptor.compression)
            
        if (pixelFormat == .invalid ) {
            completionHandler(nil, GLTFError("GLTF_3D4MCompressedTextureExtension: Failed to load texture, unsupported compression format \(descriptor.compression)."))
            return
        }
        
        if loadLevel == .all {
            var buffers = [GLTFBuffer]()
            for bView in descriptor.sources {
                let buffer = bView.buffer
                buffers.append(buffer)
            }
                            
            self.loader.load(gltf:self, resources: Set(buffers), options: ResourceType.texture) { (error) in
                var error_ = error
                var textureResult:Any?
                
                if error == nil {
                    var datas = [Data]()    
                    for buffer in buffers {
                        if buffer.data != nil {
                            datas.append(buffer.data!)
                        } else {
                            break
                        }
                    }
                    do {
                        textureResult = try self._createMetalTexture(width, height, pixelFormat, datas, bytesPerRow)
                    } catch {
                        error_ = error
                    }
                } else {
                    print(error)
                }
                completionHandler(textureResult, error_)
            }
        } else {
            let sizeWidth = (loadLevel == .first) ? 32 : descriptor.width
            let sizeHeight = (loadLevel == .first) ? 32 : descriptor.height
            let bufferView = (loadLevel == .first) ? descriptor.sources.last! : descriptor.sources.first!
            
            let buffer_ = bufferView.buffer
            self.loader.load(gltf:self, resource: buffer_, options: ResourceType.texture) { (buffer, error) in
                var error_ = error
                var textureResult:Any?
                var datas = [Data]()
                if buffer.data != nil {
                    datas.append(buffer.data!)
                    do {
                        textureResult = try self._createMetalTexture(sizeWidth, sizeHeight, pixelFormat, datas, bytesPerRow)
                    } catch {
                        error_ = error
                    }
                } else {
                    error_ = GLTFError("Can't load data for \(buffer.uri ?? "")")
                }
                
                completionHandler(textureResult, error_)
            }     
        
        }
    }
    
    fileprivate func _createMetalTexture( _ width:Int, _ height:Int, _ pixelFormat:MTLPixelFormat, _ mipmaps:[Data], _ bppBlock:(Int, Int)->Int) throws -> MTLTexture {
        var width = width
        var height = height
        let mipmapsCount = mipmaps.count
        
        if mipmapsCount == 0 {
            throw GLTFError("mipmaps array can't be empty.")
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, 
                                                                         width: width, 
                                                                         height: height, 
                                                                         mipmapped: (mipmapsCount > 1))
        textureDescriptor.mipmapLevelCount = mipmapsCount
        
        guard let device = MetalDevice.device else {
            throw GLTFError("View has Metal's render APi but can't get instance of MTLDevice.")
        }
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw GLTFError("Failed to create metal texture with descriptor \(textureDescriptor)")
        }
        
        for i in 0 ..< mipmapsCount {
            let data = mipmaps[i]
            let bPr = bppBlock(width, height)
            data.withUnsafeBytes { (unsafeBufferPointer:UnsafeRawBufferPointer) in
                if let unsafePointer = unsafeBufferPointer.bindMemory(to: UInt8.self).baseAddress {
                    texture.replace(region: MTLRegionMake2D(0, 0, width, height),
                                     mipmapLevel: i,
                                     withBytes: unsafePointer,
                                     bytesPerRow: bPr)
                }
            }
            
            width = max(width >> 1, 1);
            height = max(height >> 1, 1);
        }
        
        return texture
    }
    
    internal func _compress(image:OSImage) -> Any? {
        #if (os(iOS) || os(tvOS)) && !targetEnvironment(simulator)
        if #available(iOS 11.0, tvOS 11.0, *) {
//            if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            if let cg = image.cgImage {
                let data = CFDataCreateMutable(nil, 0)!
                let uti: CFString = "org.khronos.astc" as CFString 
                let imageDestination = CGImageDestinationCreateWithData(data, uti, 1, nil)
                CGImageDestinationAddImage(imageDestination!, cg, nil)
                CGImageDestinationFinalize(imageDestination!)
                let (bytesPerRow, pixelFormat) = _get_bpp_pixelFormat(.COMPRESSED_RGBA_ASTC_4x4)
                
                var _data = (data as Data)
                // remove astc header of 16 bytes 
                _data = _data.subdata(in: 16..<_data.count)
                
                return try? _createMetalTexture(cg.width, cg.height, pixelFormat, [_data as Data], bytesPerRow) as Any
            }
        }
        #endif
        return image
    }
    
    
    fileprivate func _get_bpp_pixelFormat(_ compression:GLTF_3D4MCompressedTextureExtensionCompression) ->((Int, Int)->Int,  MTLPixelFormat) {
        var bytesPerRow:(Int, Int)->Int = {_,_ in return 0 }
        var pixelFormat:MTLPixelFormat = .invalid;
        
        
        #if os(macOS)
        if (compression == .COMPRESSED_RGBA_S3TC_DXT1) {
            pixelFormat = .bc1_rgba
            bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
        } else if (compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT1) {
            pixelFormat = .bc1_rgba_srgb
            bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
        } else if (compression == .COMPRESSED_RGBA_S3TC_DXT3) {
            pixelFormat = .bc2_rgba
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        } else if (compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT3) {
            pixelFormat = .bc2_rgba_srgb
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        } else if (compression == .COMPRESSED_RGBA_S3TC_DXT5) {
            pixelFormat = .bc3_rgba
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        } else if (compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT5) {
            pixelFormat = .bc3_rgba_srgb
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        } else if (compression == .COMPRESSED_RGBA_BPTC_UNORM) {
            pixelFormat = .bc7_rgbaUnorm
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        } else if (compression == .COMPRESSED_SRGB_ALPHA_BPTC_UNORM) {
            pixelFormat = .bc7_rgbaUnorm_srgb
            bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
        }
        #elseif os(iOS) || os(tvOS)
        
        switch compression {
        case .ETC1_RGB8_OES:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_RGB8_ETC2:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_ETC2:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_RGBA8_ETC2_EAC:
            assert(false, " \(compression) not supported yet")
            break
        case .COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:
            assert(false, " \(compression) not supported yet")
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
            assert(false, " \(compression) can't bbe supported on iOS")
            break
        }
        
        #endif
        return (bytesPerRow, pixelFormat)
    } 
    
}
