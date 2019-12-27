//
//  GLTFCameraPerspective.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// A perspective camera containing properties to create a perspective projection matrix.
@objcMembers
open class GLTFCameraPerspective: NSObject, Codable {
    /// The floating-point aspect ratio of the field of view.
    public var aspectRatio: Double?

    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The floating-point vertical field of view in radians.
    public var yfov: Double

    /// The floating-point distance to the far clipping plane.
    public var zfar: Double?

    /// The floating-point distance to the near clipping plane.
    public var znear: Double

    private enum CodingKeys: String, CodingKey {
        case aspectRatio
        case extensions
        case extras
        case yfov
        case zfar
        case znear
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aspectRatio = try? container.decode(Double.self, forKey: .aspectRatio)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        yfov = try container.decode(Double.self, forKey: .yfov)
        zfar = try? container.decode(Double.self, forKey: .zfar)
        znear = try container.decode(Double.self, forKey: .znear)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(aspectRatio, forKey: .aspectRatio)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(yfov, forKey: .yfov)
        try container.encode(zfar, forKey: .zfar)
        try container.encode(znear, forKey: .znear)
    }
}
