//
//  GLTFCameraOrthographic.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// An orthographic camera containing properties to create an orthographic projection matrix.
@objcMembers
open class GLTFCameraOrthographic: NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The floating-point horizontal magnification of the view. Must not be zero.
    public var xmag: Double

    /// The floating-point vertical magnification of the view. Must not be zero.
    public var ymag: Double

    /// The floating-point distance to the far clipping plane. `zfar` must be greater than `znear`.
    public var zfar: Double

    /// The floating-point distance to the near clipping plane.
    public var znear: Double

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case xmag
        case ymag
        case zfar
        case znear
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        xmag = try container.decode(Double.self, forKey: .xmag)
        ymag = try container.decode(Double.self, forKey: .ymag)
        zfar = try container.decode(Double.self, forKey: .zfar)
        znear = try container.decode(Double.self, forKey: .znear)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(xmag, forKey: .xmag)
        try container.encode(ymag, forKey: .ymag)
        try container.encode(zfar, forKey: .zfar)
        try container.encode(znear, forKey: .znear)
    }
}
