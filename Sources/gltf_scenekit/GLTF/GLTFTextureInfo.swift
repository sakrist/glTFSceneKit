//
//  GLTFTextureInfo.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// Reference to a texture.
@objcMembers
open class GLTFTextureInfo : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The index of the texture.
    public var index:Int

    /// The set index of texture's TEXCOORD attribute used for texture coordinate mapping.
    public var texCoord:Int

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case index
        case texCoord
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        index = try container.decode(Int.self, forKey: .index)
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
        try container.encode(texCoord, forKey: .texCoord)
    }
}
