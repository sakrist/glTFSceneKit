//
//  GLTFMaterial.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFMaterialAlphaMode: Int, RawRepresentable, Codable {
    case OPAQUE
    case MASK
    case BLEND

    public var rawValue: String {
        switch self {
        case .OPAQUE:
            return "OPAQUE"
        case .MASK:
            return "MASK"
        case .BLEND:
            return "BLEND"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "OPAQUE":
            self = .OPAQUE
        case "MASK":
            self = .MASK
        case "BLEND":
            self = .BLEND
        default:
            return nil
        }
    }

    public init() {
        self = .OPAQUE
    }
}

/// The material appearance of a primitive.
@objcMembers
open class GLTFMaterial: NSObject, Codable {
    /// The alpha cutoff value of the material.
    public var alphaCutoff: Double

    /// The alpha rendering mode of the material.
    public var alphaMode: GLTFMaterialAlphaMode

    /// Specifies whether the material is double sided.
    public var doubleSided: Bool

    /// The emissive color of the material.
    public var emissiveFactor: [Double]

    /// Reference to a texture.
    public var emissiveTexture: GLTFTextureInfo?

    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The user-defined name of this object.
    public var name: String?

    /// The normal map texture.
    public var normalTexture: GLTFMaterialNormalTextureInfo?

    /// The occlusion map texture.
    public var occlusionTexture: GLTFMaterialOcclusionTextureInfo?

    /// A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology.
    public var pbrMetallicRoughness: GLTFMaterialPBRMetallicRoughness?

    private enum CodingKeys: String, CodingKey {
        case alphaCutoff
        case alphaMode
        case doubleSided
        case emissiveFactor
        case emissiveTexture
        case extensions
        case extras
        case name
        case normalTexture
        case occlusionTexture
        case pbrMetallicRoughness
    }

    public override init() {
        alphaCutoff = 0.5
        alphaMode = GLTFMaterialAlphaMode()
        doubleSided = false
        emissiveFactor = [0, 0, 0]
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            alphaCutoff = try container.decode(Double.self, forKey: .alphaCutoff)
        } catch {
            alphaCutoff = 0.5
        }
        do {
            alphaMode = try container.decode(GLTFMaterialAlphaMode.self, forKey: .alphaMode)
        } catch {
            alphaMode = GLTFMaterialAlphaMode()
        }
        do {
            doubleSided = try container.decode(Bool.self, forKey: .doubleSided)
        } catch {
            doubleSided = false
        }
        do {
            emissiveFactor = try container.decode([Double].self, forKey: .emissiveFactor)
        } catch {
            emissiveFactor = [0, 0, 0]
        }
        emissiveTexture = try? container.decode(GLTFTextureInfo.self, forKey: .emissiveTexture)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        normalTexture = try? container.decode(GLTFMaterialNormalTextureInfo.self, forKey: .normalTexture)
        occlusionTexture = try? container.decode(GLTFMaterialOcclusionTextureInfo.self, forKey: .occlusionTexture)
        pbrMetallicRoughness = try? container.decode(GLTFMaterialPBRMetallicRoughness.self, forKey: .pbrMetallicRoughness)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(alphaCutoff, forKey: .alphaCutoff)
        try container.encode(alphaMode, forKey: .alphaMode)
        try container.encode(doubleSided, forKey: .doubleSided)
        try container.encode(emissiveFactor, forKey: .emissiveFactor)
        try container.encode(emissiveTexture, forKey: .emissiveTexture)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(normalTexture, forKey: .normalTexture)
        try container.encode(occlusionTexture, forKey: .occlusionTexture)
        try container.encode(pbrMetallicRoughness, forKey: .pbrMetallicRoughness)
    }
}
