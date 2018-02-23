//
//  GLTFAnimation.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// A keyframe animation.
@objcMembers
open class GLTFAnimation : NSObject, Codable {
    /// An array of channels, each of which targets an animation's sampler at a node's property. Different channels of the same animation can't have equal targets.
    public var channels:[GLTFAnimationChannel]

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The user-defined name of this object.
    public var name:String?

    /// An array of samplers that combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target).
    public var samplers:[GLTFAnimationSampler]

    private enum CodingKeys: String, CodingKey {
        case channels
        case extensions
        case extras
        case name
        case samplers
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channels = try container.decode([GLTFAnimationChannel].self, forKey: .channels)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        samplers = try container.decode([GLTFAnimationSampler].self, forKey: .samplers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(channels, forKey: .channels)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(samplers, forKey: .samplers)
    }
}
