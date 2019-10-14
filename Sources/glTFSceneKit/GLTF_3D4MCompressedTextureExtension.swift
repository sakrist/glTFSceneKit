//
//  GLTF_3D4MCompressedTextureExtension.swift
//
//  Created by sakrist on 17/03/2018.
//  Copyright © 2018 None. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

public enum GLTF_3D4MCompressedTextureExtensionCompression: Int, RawRepresentable, Codable {
    case ETC1_RGB8_OES = 36196
    case COMPRESSED_RGB8_ETC2 = 37492
    case COMPRESSED_SRGB8_ETC2 = 37493
    case COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 37494
    case COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 37495
    case COMPRESSED_RGBA8_ETC2_EAC = 37496
    case COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 37497
    case COMPRESSED_SRGB_PVRTC_2BPPV1 = 35412
    case COMPRESSED_SRGB_PVRTC_4BPPV1 = 35413
    case COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1 = 35414
    case COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1 = 35415
    case COMPRESSED_RGB_PVRTC_4BPPV1 = 35840
    case COMPRESSED_RGB_PVRTC_2BPPV1 = 35841
    case COMPRESSED_RGBA_PVRTC_4BPPV1 = 35842
    case COMPRESSED_RGBA_PVRTC_2BPPV1 = 35843
    case COMPRESSED_RGBA_ASTC_4x4 = 37808
    case COMPRESSED_RGBA_ASTC_5x4 = 37809
    case COMPRESSED_RGBA_ASTC_5x5 = 37810
    case COMPRESSED_RGBA_ASTC_6x5 = 37811
    case COMPRESSED_RGBA_ASTC_6x6 = 37812
    case COMPRESSED_RGBA_ASTC_8x5 = 37813
    case COMPRESSED_RGBA_ASTC_8x6 = 37814
    case COMPRESSED_RGBA_ASTC_8x8 = 37815
    case COMPRESSED_RGBA_ASTC_10x5 = 37816
    case COMPRESSED_RGBA_ASTC_10x6 = 37817
    case COMPRESSED_RGBA_ASTC_10x8 = 37818
    case COMPRESSED_RGBA_ASTC_10x10 = 37819
    case COMPRESSED_RGBA_ASTC_12x10 = 37820
    case COMPRESSED_RGBA_ASTC_12x12 = 37821
    case COMPRESSED_SRGB8_ALPHA8_ASTC_4x4 = 37840
    case COMPRESSED_SRGB8_ALPHA8_ASTC_5x4 = 37841
    case COMPRESSED_SRGB8_ALPHA8_ASTC_5x5 = 37842
    case COMPRESSED_SRGB8_ALPHA8_ASTC_6x5 = 37843
    case COMPRESSED_SRGB8_ALPHA8_ASTC_6x6 = 37844
    case COMPRESSED_SRGB8_ALPHA8_ASTC_8x5 = 37845
    case COMPRESSED_SRGB8_ALPHA8_ASTC_8x6 = 37846
    case COMPRESSED_SRGB8_ALPHA8_ASTC_8x8 = 37847
    case COMPRESSED_SRGB8_ALPHA8_ASTC_10x5 = 37848
    case COMPRESSED_SRGB8_ALPHA8_ASTC_10x6 = 37849
    case COMPRESSED_SRGB8_ALPHA8_ASTC_10x8 = 37850
    case COMPRESSED_SRGB8_ALPHA8_ASTC_10x10 = 37851
    case COMPRESSED_SRGB8_ALPHA8_ASTC_12x10 = 37852
    case COMPRESSED_SRGB8_ALPHA8_ASTC_12x12 = 37853
    case COMPRESSED_RGB_S3TC_DXT1 = 33776
    case COMPRESSED_RGBA_S3TC_DXT1 = 33777
    case COMPRESSED_RGBA_S3TC_DXT3 = 33778
    case COMPRESSED_RGBA_S3TC_DXT5 = 33779
    case COMPRESSED_SRGB_S3TC_DXT1 = 35916
    case COMPRESSED_SRGB_ALPHA_S3TC_DXT1 = 35917
    case COMPRESSED_SRGB_ALPHA_S3TC_DXT3 = 35918
    case COMPRESSED_SRGB_ALPHA_S3TC_DXT5 = 35919
    case COMPRESSED_RGBA_BPTC_UNORM = 36492
    case COMPRESSED_SRGB_ALPHA_BPTC_UNORM = 36493

    public var rawValue: Int {
        switch self {
        case .ETC1_RGB8_OES:
            return 36196
        case .COMPRESSED_RGB8_ETC2:
            return 37492
        case .COMPRESSED_SRGB8_ETC2:
            return 37493
        case .COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            return 37494
        case .COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:
            return 37495
        case .COMPRESSED_RGBA8_ETC2_EAC:
            return 37496
        case .COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:
            return 37497
        case .COMPRESSED_SRGB_PVRTC_2BPPV1:
            return 35412
        case .COMPRESSED_SRGB_PVRTC_4BPPV1:
            return 35413
        case .COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1:
            return 35414
        case .COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1:
            return 35415
        case .COMPRESSED_RGB_PVRTC_4BPPV1:
            return 35840
        case .COMPRESSED_RGB_PVRTC_2BPPV1:
            return 35841
        case .COMPRESSED_RGBA_PVRTC_4BPPV1:
            return 35842
        case .COMPRESSED_RGBA_PVRTC_2BPPV1:
            return 35843
        case .COMPRESSED_RGBA_ASTC_4x4:
            return 37808
        case .COMPRESSED_RGBA_ASTC_5x4:
            return 37809
        case .COMPRESSED_RGBA_ASTC_5x5:
            return 37810
        case .COMPRESSED_RGBA_ASTC_6x5:
            return 37811
        case .COMPRESSED_RGBA_ASTC_6x6:
            return 37812
        case .COMPRESSED_RGBA_ASTC_8x5:
            return 37813
        case .COMPRESSED_RGBA_ASTC_8x6:
            return 37814
        case .COMPRESSED_RGBA_ASTC_8x8:
            return 37815
        case .COMPRESSED_RGBA_ASTC_10x5:
            return 37816
        case .COMPRESSED_RGBA_ASTC_10x6:
            return 37817
        case .COMPRESSED_RGBA_ASTC_10x8:
            return 37818
        case .COMPRESSED_RGBA_ASTC_10x10:
            return 37819
        case .COMPRESSED_RGBA_ASTC_12x10:
            return 37820
        case .COMPRESSED_RGBA_ASTC_12x12:
            return 37821
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_4x4:
            return 37840
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_5x4:
            return 37841
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_5x5:
            return 37842
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_6x5:
            return 37843
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_6x6:
            return 37844
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x5:
            return 37845
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x6:
            return 37846
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_8x8:
            return 37847
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x5:
            return 37848
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x6:
            return 37849
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x8:
            return 37850
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_10x10:
            return 37851
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_12x10:
            return 37852
        case .COMPRESSED_SRGB8_ALPHA8_ASTC_12x12:
            return 37853
        case .COMPRESSED_RGB_S3TC_DXT1:
            return 33776
        case .COMPRESSED_RGBA_S3TC_DXT1:
            return 33777
        case .COMPRESSED_RGBA_S3TC_DXT3:
            return 33778
        case .COMPRESSED_RGBA_S3TC_DXT5:
            return 33779
        case .COMPRESSED_SRGB_S3TC_DXT1:
            return 35916
        case .COMPRESSED_SRGB_ALPHA_S3TC_DXT1:
            return 35917
        case .COMPRESSED_SRGB_ALPHA_S3TC_DXT3:
            return 35918
        case .COMPRESSED_SRGB_ALPHA_S3TC_DXT5:
            return 35919
        case .COMPRESSED_RGBA_BPTC_UNORM:
            return 36492
        case .COMPRESSED_SRGB_ALPHA_BPTC_UNORM:
            return 36493
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 36196:
            self = .ETC1_RGB8_OES
        case 37492:
            self = .COMPRESSED_RGB8_ETC2
        case 37493:
            self = .COMPRESSED_SRGB8_ETC2
        case 37494:
            self = .COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2
        case 37495:
            self = .COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2
        case 37496:
            self = .COMPRESSED_RGBA8_ETC2_EAC
        case 37497:
            self = .COMPRESSED_SRGB8_ALPHA8_ETC2_EAC
        case 35412:
            self = .COMPRESSED_SRGB_PVRTC_2BPPV1
        case 35413:
            self = .COMPRESSED_SRGB_PVRTC_4BPPV1
        case 35414:
            self = .COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1
        case 35415:
            self = .COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1
        case 35840:
            self = .COMPRESSED_RGB_PVRTC_4BPPV1
        case 35841:
            self = .COMPRESSED_RGB_PVRTC_2BPPV1
        case 35842:
            self = .COMPRESSED_RGBA_PVRTC_4BPPV1
        case 35843:
            self = .COMPRESSED_RGBA_PVRTC_2BPPV1
        case 37808:
            self = .COMPRESSED_RGBA_ASTC_4x4
        case 37809:
            self = .COMPRESSED_RGBA_ASTC_5x4
        case 37810:
            self = .COMPRESSED_RGBA_ASTC_5x5
        case 37811:
            self = .COMPRESSED_RGBA_ASTC_6x5
        case 37812:
            self = .COMPRESSED_RGBA_ASTC_6x6
        case 37813:
            self = .COMPRESSED_RGBA_ASTC_8x5
        case 37814:
            self = .COMPRESSED_RGBA_ASTC_8x6
        case 37815:
            self = .COMPRESSED_RGBA_ASTC_8x8
        case 37816:
            self = .COMPRESSED_RGBA_ASTC_10x5
        case 37817:
            self = .COMPRESSED_RGBA_ASTC_10x6
        case 37818:
            self = .COMPRESSED_RGBA_ASTC_10x8
        case 37819:
            self = .COMPRESSED_RGBA_ASTC_10x10
        case 37820:
            self = .COMPRESSED_RGBA_ASTC_12x10
        case 37821:
            self = .COMPRESSED_RGBA_ASTC_12x12
        case 37840:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_4x4
        case 37841:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_5x4
        case 37842:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_5x5
        case 37843:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_6x5
        case 37844:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_6x6
        case 37845:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_8x5
        case 37846:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_8x6
        case 37847:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_8x8
        case 37848:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_10x5
        case 37849:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_10x6
        case 37850:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_10x8
        case 37851:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_10x10
        case 37852:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_12x10
        case 37853:
            self = .COMPRESSED_SRGB8_ALPHA8_ASTC_12x12
        case 33776:
            self = .COMPRESSED_RGB_S3TC_DXT1
        case 33777:
            self = .COMPRESSED_RGBA_S3TC_DXT1
        case 33778:
            self = .COMPRESSED_RGBA_S3TC_DXT3
        case 33779:
            self = .COMPRESSED_RGBA_S3TC_DXT5
        case 35916:
            self = .COMPRESSED_SRGB_S3TC_DXT1
        case 35917:
            self = .COMPRESSED_SRGB_ALPHA_S3TC_DXT1
        case 35918:
            self = .COMPRESSED_SRGB_ALPHA_S3TC_DXT3
        case 35919:
            self = .COMPRESSED_SRGB_ALPHA_S3TC_DXT5
        case 36492:
            self = .COMPRESSED_RGBA_BPTC_UNORM
        case 36493:
            self = .COMPRESSED_SRGB_ALPHA_BPTC_UNORM
        default:
            return nil
        }
    }

}

public enum GLTF_3D4MCompressedTextureExtensionTarget: Int, RawRepresentable, Codable {
    case TEXTURE_1D = 3552
    case TEXTURE_2D = 3553
    case TEXTURE_3D = 32879
    case TEXTURE_CUBE_MAP = 34067
    case TEXTURE_1D_ARRAY = 35864
    case TEXTURE_2D_ARRAY = 35866
    case TEXTURE_CUBE_MAP_ARRAY = 36873

    public var rawValue: Int {
        switch self {
        case .TEXTURE_1D:
            return 3552
        case .TEXTURE_2D:
            return 3553
        case .TEXTURE_3D:
            return 32879
        case .TEXTURE_CUBE_MAP:
            return 34067
        case .TEXTURE_1D_ARRAY:
            return 35864
        case .TEXTURE_2D_ARRAY:
            return 35866
        case .TEXTURE_CUBE_MAP_ARRAY:
            return 36873
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 3552:
            self = .TEXTURE_1D
        case 3553:
            self = .TEXTURE_2D
        case 32879:
            self = .TEXTURE_3D
        case 34067:
            self = .TEXTURE_CUBE_MAP
        case 35864:
            self = .TEXTURE_1D_ARRAY
        case 35866:
            self = .TEXTURE_2D_ARRAY
        case 36873:
            self = .TEXTURE_CUBE_MAP_ARRAY
        default:
            return nil
        }
    }

    public init() {
        self = .TEXTURE_2D
    }
}


/// Class template
open class GLTF_3D4MCompressedTextureExtension : Codable {
    /// Compression type.
    public var compression:GLTF_3D4MCompressedTextureExtensionCompression

    /// Texture width size in pixels.
    public var width:Int

    /// Texture height size in pixels.
    public var height:Int

    /// Texture index of bufferView used for each level of texture. First source representing level 0. Each next is divide by 2 of previous texture size. For example 0 level is 1024, next is 512 and next 256 ans so on.
    public var sources:[GLTFBufferView]

    /// Texture 2D target.
    public var target:GLTF_3D4MCompressedTextureExtensionTarget

    private enum CodingKeys: String, CodingKey {
        case compression
        case height
        case sources
        case target
        case width
    }

    public init(compression c:GLTF_3D4MCompressedTextureExtensionCompression, 
                width w:Int,
                height h:Int,
                sources s:[GLTFBufferView],
                target t:GLTF_3D4MCompressedTextureExtensionTarget) {
        compression = c 
        width = w
        height = h
        sources = s
        target = t
    } 
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        compression = try container.decode(GLTF_3D4MCompressedTextureExtensionCompression.self, forKey: .compression)
        do {
            height = try container.decode(Int.self, forKey: .height)
        } catch {
            height = 0
        }
        sources = try container.decode([GLTFBufferView].self, forKey: .sources)
        do {
            target = try container.decode(GLTF_3D4MCompressedTextureExtensionTarget.self, forKey: .target)
        } catch {
            target = GLTF_3D4MCompressedTextureExtensionTarget()
        }
        do {
            width = try container.decode(Int.self, forKey: .width)
        } catch {
            width = 0
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(compression, forKey: .compression)
        try container.encode(height, forKey: .height)
        try container.encode(sources, forKey: .sources)
        try container.encode(target, forKey: .target)
        try container.encode(width, forKey: .width)
    }
}
