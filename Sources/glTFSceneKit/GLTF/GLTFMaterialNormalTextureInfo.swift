//
//  GLTFMaterialNormalTextureInfo.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// The normal map texture.
@objcMembers
open class GLTFMaterialNormalTextureInfo : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The index of the texture.
    public var index:Int?

    /// The scalar multiplier applied to each normal vector of the normal texture.
    public var scale:Double

    /// The set index of texture's TEXCOORD attribute used for texture coordinate mapping.
    public var texCoord:Int

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case index
        case scale
        case texCoord
    }

    public override init() {
        scale = 1
        texCoord = 0
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        index = try? container.decode(Int.self, forKey: .index)
        do {
            scale = try container.decode(Double.self, forKey: .scale)
        } catch {
            scale = 1
        }
        do {
            texCoord = try container.decode(Int.self, forKey: .texCoord)
        } catch {
            texCoord = 0
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(index, forKey: .index)
        try container.encode(scale, forKey: .scale)
        try container.encode(texCoord, forKey: .texCoord)
    }
}
