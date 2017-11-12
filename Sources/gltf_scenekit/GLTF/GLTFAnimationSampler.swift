//
//  GLTFAnimationSampler.swift
//
//  Created by Volodymyr Boichentsov on 09/11/2017.
//  Copyright © 2017 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFAnimationSamplerInterpolation: Int, RawRepresentable, Codable {
    case LINEAR
    case STEP
    case CATMULLROMSPLINE
    case CUBICSPLINE

    public var rawValue: String {
        switch self {
        case .LINEAR:
            return "LINEAR"
        case .STEP:
            return "STEP"
        case .CATMULLROMSPLINE:
            return "CATMULLROMSPLINE"
        case .CUBICSPLINE:
            return "CUBICSPLINE"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "LINEAR":
            self = .LINEAR
        case "STEP":
            self = .STEP
        case "CATMULLROMSPLINE":
            self = .CATMULLROMSPLINE
        case "CUBICSPLINE":
            self = .CUBICSPLINE
        default:
            return nil
        }
    }

    public init() {
        self = .LINEAR
    }
}


/// Combines input and output accessors with an interpolation algorithm to define a keyframe graph (but not its target).
@objcMembers
open class GLTFAnimationSampler : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: [String: Codable]]?

    /// Application-specific data.
    public var extras:[String: Codable]?

    /// The index of an accessor containing keyframe input values, e.g., time.
    public var input:Int?

    /// Interpolation algorithm.
    public var interpolation:GLTFAnimationSamplerInterpolation

    /// The index of an accessor, containing keyframe output values.
    public var output:Int?

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case input
        case interpolation
        case output
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: [String: Codable]].self, forKey: .extensions)
        extras = try? container.decode([String: Codable].self, forKey: .extras)
        input = try? container.decode(Int.self, forKey: .input)
        do {
            interpolation = try container.decode(GLTFAnimationSamplerInterpolation.self, forKey: .interpolation)
        } catch {
            interpolation = GLTFAnimationSamplerInterpolation()
        }
        output = try? container.decode(Int.self, forKey: .output)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(input, forKey: .input)
        try container.encode(interpolation, forKey: .interpolation)
        try container.encode(output, forKey: .output)
    }
}
