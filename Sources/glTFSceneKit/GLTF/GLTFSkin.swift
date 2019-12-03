//
//  GLTFSkin.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// Joints and matrices defining a skin.
@objcMembers
open class GLTFSkin: NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// The index of the accessor containing the floating-point 4x4 inverse-bind matrices.  The default is that each matrix is a 4x4 identity matrix, which implies that inverse-bind matrices were pre-applied.
    public var inverseBindMatrices: Int?

    /// Indices of skeleton nodes, used as joints in this skin.
    public var joints: [Int]

    /// The user-defined name of this object.
    public var name: String?

    /// The index of the node used as a skeleton root. When undefined, joints transforms resolve to scene root.
    public var skeleton: Int?

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case inverseBindMatrices
        case joints
        case name
        case skeleton
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        inverseBindMatrices = try? container.decode(Int.self, forKey: .inverseBindMatrices)
        joints = try container.decode([Int].self, forKey: .joints)
        name = try? container.decode(String.self, forKey: .name)
        skeleton = try? container.decode(Int.self, forKey: .skeleton)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(inverseBindMatrices, forKey: .inverseBindMatrices)
        try container.encode(joints, forKey: .joints)
        try container.encode(name, forKey: .name)
        try container.encode(skeleton, forKey: .skeleton)
    }
}
