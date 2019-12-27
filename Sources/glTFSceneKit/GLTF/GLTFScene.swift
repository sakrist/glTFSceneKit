//
//  GLTFScene.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// The root nodes of a scene.
@objcMembers
open class GLTFScene: NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The user-defined name of this object.
    public var name: String?

    /// The indices of each root node.
    public var nodes: [Int]?

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case name
        case nodes
    }

    public override init() {}

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        nodes = try? container.decode([Int].self, forKey: .nodes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(nodes, forKey: .nodes)
    }
}
