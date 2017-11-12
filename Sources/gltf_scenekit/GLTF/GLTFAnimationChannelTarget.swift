//
//  GLTFAnimationChannelTarget.swift
//
//  Created by Volodymyr Boichentsov on 09/11/2017.
//  Copyright © 2017 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFAnimationChannelTargetPath: Int, RawRepresentable, Codable {
    case translation
    case rotation
    case scale
    case weights

    public var rawValue: String {
        switch self {
        case .translation:
            return "translation"
        case .rotation:
            return "rotation"
        case .scale:
            return "scale"
        case .weights:
            return "weights"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "translation":
            self = .translation
        case "rotation":
            self = .rotation
        case "scale":
            self = .scale
        case "weights":
            self = .weights
        default:
            return nil
        }
    }

}


/// The index of the node and TRS property that an animation channel targets.
@objcMembers
open class GLTFAnimationChannelTarget : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: [String: Codable]]?

    /// Application-specific data.
    public var extras:[String: Codable]?

    /// The index of the node to target.
    public var node:Int?

    /// The name of the node's TRS property to modify, or the "weights" of the Morph Targets it instantiates.
    public var path:GLTFAnimationChannelTargetPath?

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case node
        case path
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: [String: Codable]].self, forKey: .extensions)
        extras = try? container.decode([String: Codable].self, forKey: .extras)
        node = try? container.decode(Int.self, forKey: .node)
        path = try? container.decode(GLTFAnimationChannelTargetPath.self, forKey: .path)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(node, forKey: .node)
        try container.encode(path, forKey: .path)
    }
}
