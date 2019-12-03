//
//  GLTFAnimationChannel.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// Targets an animation's sampler at a node's property.
@objcMembers
open class GLTFAnimationChannel: NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The index of a sampler in this animation used to compute the value for the target.
    public var sampler: Int

    /// The index of the node and TRS property that an animation channel targets.
    public var target: GLTFAnimationChannelTarget

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case sampler
        case target
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        sampler = try container.decode(Int.self, forKey: .sampler)
        target = try container.decode(GLTFAnimationChannelTarget.self, forKey: .target)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(sampler, forKey: .sampler)
        try container.encode(target, forKey: .target)
    }
}
