//
//  GLTFSampler.swift
//
//  Created by Volodymyr Boichentsov on 09/11/2017.
//  Copyright © 2017 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFSamplerMagFilter: Int, RawRepresentable, Codable {
    case NEAREST = 9728
    case LINEAR = 9729

    public var rawValue: Int {
        switch self {
        case .NEAREST:
            return 9728
        case .LINEAR:
            return 9729
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 9728:
            self = .NEAREST
        case 9729:
            self = .LINEAR
        default:
            return nil
        }
    }

}

@objc public enum GLTFSamplerMinFilter: Int, RawRepresentable, Codable {
    case NEAREST = 9728
    case LINEAR = 9729
    case NEAREST_MIPMAP_NEAREST = 9984
    case LINEAR_MIPMAP_NEAREST = 9985
    case NEAREST_MIPMAP_LINEAR = 9986
    case LINEAR_MIPMAP_LINEAR = 9987

    public var rawValue: Int {
        switch self {
        case .NEAREST:
            return 9728
        case .LINEAR:
            return 9729
        case .NEAREST_MIPMAP_NEAREST:
            return 9984
        case .LINEAR_MIPMAP_NEAREST:
            return 9985
        case .NEAREST_MIPMAP_LINEAR:
            return 9986
        case .LINEAR_MIPMAP_LINEAR:
            return 9987
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 9728:
            self = .NEAREST
        case 9729:
            self = .LINEAR
        case 9984:
            self = .NEAREST_MIPMAP_NEAREST
        case 9985:
            self = .LINEAR_MIPMAP_NEAREST
        case 9986:
            self = .NEAREST_MIPMAP_LINEAR
        case 9987:
            self = .LINEAR_MIPMAP_LINEAR
        default:
            return nil
        }
    }

}

@objc public enum GLTFSamplerWrapS: Int, RawRepresentable, Codable {
    case CLAMP_TO_EDGE = 33071
    case MIRRORED_REPEAT = 33648
    case REPEAT = 10497

    public var rawValue: Int {
        switch self {
        case .CLAMP_TO_EDGE:
            return 33071
        case .MIRRORED_REPEAT:
            return 33648
        case .REPEAT:
            return 10497
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 33071:
            self = .CLAMP_TO_EDGE
        case 33648:
            self = .MIRRORED_REPEAT
        case 10497:
            self = .REPEAT
        default:
            return nil
        }
    }

    public init() {
        self = .REPEAT
    }
}

@objc public enum GLTFSamplerWrapT: Int, RawRepresentable, Codable {
    case CLAMP_TO_EDGE = 33071
    case MIRRORED_REPEAT = 33648
    case REPEAT = 10497

    public var rawValue: Int {
        switch self {
        case .CLAMP_TO_EDGE:
            return 33071
        case .MIRRORED_REPEAT:
            return 33648
        case .REPEAT:
            return 10497
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 33071:
            self = .CLAMP_TO_EDGE
        case 33648:
            self = .MIRRORED_REPEAT
        case 10497:
            self = .REPEAT
        default:
            return nil
        }
    }

    public init() {
        self = .REPEAT
    }
}


/// Texture sampler properties for filtering and wrapping modes.
@objcMembers
open class GLTFSampler : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: [String: Codable]]?

    /// Application-specific data.
    public var extras:[String: Codable]?

    /// Magnification filter.
    public var magFilter:GLTFSamplerMagFilter?

    /// Minification filter.
    public var minFilter:GLTFSamplerMinFilter?

    /// The user-defined name of this object.
    public var name:String?

    /// s wrapping mode.
    public var wrapS:GLTFSamplerWrapS

    /// t wrapping mode.
    public var wrapT:GLTFSamplerWrapT

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case magFilter
        case minFilter
        case name
        case wrapS
        case wrapT
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: [String: Codable]].self, forKey: .extensions)
        extras = try? container.decode([String: Codable].self, forKey: .extras)
        magFilter = try? container.decode(GLTFSamplerMagFilter.self, forKey: .magFilter)
        minFilter = try? container.decode(GLTFSamplerMinFilter.self, forKey: .minFilter)
        name = try? container.decode(String.self, forKey: .name)
        do {
            wrapS = try container.decode(GLTFSamplerWrapS.self, forKey: .wrapS)
        } catch {
            wrapS = GLTFSamplerWrapS()
        }
        do {
            wrapT = try container.decode(GLTFSamplerWrapT.self, forKey: .wrapT)
        } catch {
            wrapT = GLTFSamplerWrapT()
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(magFilter, forKey: .magFilter)
        try container.encode(minFilter, forKey: .minFilter)
        try container.encode(name, forKey: .name)
        try container.encode(wrapS, forKey: .wrapS)
        try container.encode(wrapT, forKey: .wrapT)
    }
}
