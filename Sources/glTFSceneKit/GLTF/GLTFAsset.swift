//
//  GLTFAsset.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// Metadata about the glTF asset.
@objcMembers
open class GLTFAsset: NSObject, Codable {
    /// A copyright message suitable for display to credit the content creator.
    public var copyright: String?

    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// Tool that generated this glTF model.  Useful for debugging.
    public var generator: String?

    /// The minimum glTF version that this asset targets.
    public var minVersion: String?

    /// The glTF version that this asset targets.
    public var version: String

    private enum CodingKeys: String, CodingKey {
        case copyright
        case extensions
        case extras
        case generator
        case minVersion
        case version
    }

    public init(version v: String) {
        version = v
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        copyright = try? container.decode(String.self, forKey: .copyright)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        generator = try? container.decode(String.self, forKey: .generator)
        minVersion = try? container.decode(String.self, forKey: .minVersion)
        version = try container.decode(String.self, forKey: .version)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(copyright, forKey: .copyright)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(generator, forKey: .generator)
        try container.encode(minVersion, forKey: .minVersion)
        try container.encode(version, forKey: .version)
    }
}
