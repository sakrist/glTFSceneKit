//
//  GLTFMaterialPBRMetallicRoughness.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// A set of parameter values that are used to define the metallic-roughness material model from Physically-Based Rendering (PBR) methodology.
@objcMembers
open class GLTFMaterialPBRMetallicRoughness : NSObject, Codable {
    /// The material's base color factor.
    public var baseColorFactor:[Double]

    /// Reference to a texture.
    public var baseColorTexture:GLTFTextureInfo?

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The metalness of the material.
    public var metallicFactor:Double

    /// Reference to a texture.
    public var metallicRoughnessTexture:GLTFTextureInfo?

    /// The roughness of the material.
    public var roughnessFactor:Double

    private enum CodingKeys: String, CodingKey {
        case baseColorFactor
        case baseColorTexture
        case extensions
        case extras
        case metallicFactor
        case metallicRoughnessTexture
        case roughnessFactor
    }

    public override init() {
        baseColorFactor = [1, 1, 1, 1]
        metallicFactor = 1
        roughnessFactor = 1
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            baseColorFactor = try container.decode([Double].self, forKey: .baseColorFactor)
        } catch {
            baseColorFactor = [1, 1, 1, 1]
        }
        baseColorTexture = try? container.decode(GLTFTextureInfo.self, forKey: .baseColorTexture)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        do {
            metallicFactor = try container.decode(Double.self, forKey: .metallicFactor)
        } catch {
            metallicFactor = 1
        }
        metallicRoughnessTexture = try? container.decode(GLTFTextureInfo.self, forKey: .metallicRoughnessTexture)
        do {
            roughnessFactor = try container.decode(Double.self, forKey: .roughnessFactor)
        } catch {
            roughnessFactor = 1
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseColorFactor, forKey: .baseColorFactor)
        try container.encode(baseColorTexture, forKey: .baseColorTexture)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(metallicFactor, forKey: .metallicFactor)
        try container.encode(metallicRoughnessTexture, forKey: .metallicRoughnessTexture)
        try container.encode(roughnessFactor, forKey: .roughnessFactor)
    }
}
