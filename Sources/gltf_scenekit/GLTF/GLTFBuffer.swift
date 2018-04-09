//
//  GLTFBuffer.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// A buffer points to binary geometry, animation, or skins.
@objcMembers
open class GLTFBuffer : NSObject, Codable {
    /// The length of the buffer in bytes.
    public var byteLength:Int

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The user-defined name of this object.
    public var name:String?

    /// The uri of the buffer.
    public var uri:String?

    var lock = os_unfair_lock_s()
    
    private enum CodingKeys: String, CodingKey {
        case byteLength
        case extensions
        case extras
        case name
        case uri
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        byteLength = try container.decode(Int.self, forKey: .byteLength)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        uri = try? container.decode(String.self, forKey: .uri)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(byteLength, forKey: .byteLength)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(uri, forKey: .uri)
    }
}
