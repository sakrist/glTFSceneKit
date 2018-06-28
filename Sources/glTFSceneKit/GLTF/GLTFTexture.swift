//
//  GLTFTexture.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// A texture and its sampler.
@objcMembers
open class GLTFTexture : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The user-defined name of this object.
    public var name:String?

    /// The index of the sampler used by this texture. When undefined, a sampler with repeat wrapping and auto filtering should be used.
    public var sampler:Int?

    /// The index of the image used by this texture.
    public var source:Int?
    
    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case name
        case sampler
        case source
    }

    public override init() { }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: GLTF_3D4MCompressedTextureExtension].self, forKey: .extensions)        
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        sampler = try? container.decode(Int.self, forKey: .sampler)
        source = try? container.decode(Int.self, forKey: .source)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(extensions as? [String: GLTF_3D4MCompressedTextureExtension], forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(sampler, forKey: .sampler)
        try container.encode(source, forKey: .source)
    }
}


extension KeyedEncodingContainerProtocol {
    mutating func encode(_ value: [String: GLTF_3D4MCompressedTextureExtension]?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
            try container.encode(value!)
        }
    }
}

