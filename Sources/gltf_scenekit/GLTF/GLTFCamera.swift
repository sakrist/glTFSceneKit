//
//  GLTFCamera.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFCameraType: Int, RawRepresentable, Codable {
    case perspective
    case orthographic

    public var rawValue: String {
        switch self {
        case .perspective:
            return "perspective"
        case .orthographic:
            return "orthographic"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "perspective":
            self = .perspective
        case "orthographic":
            self = .orthographic
        default:
            return nil
        }
    }

}


/// A camera's projection.  A node can reference a camera to apply a transform to place the camera in the scene.
@objcMembers
open class GLTFCamera : NSObject, Codable {
    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The user-defined name of this object.
    public var name:String?

    /// An orthographic camera containing properties to create an orthographic projection matrix.
    public var orthographic:GLTFCameraOrthographic?

    /// A perspective camera containing properties to create a perspective projection matrix.
    public var perspective:GLTFCameraPerspective?

    /// Specifies if the camera uses a perspective or orthographic projection.
    public var type:GLTFCameraType

    private enum CodingKeys: String, CodingKey {
        case extensions
        case extras
        case name
        case orthographic
        case perspective
        case type
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        orthographic = try? container.decode(GLTFCameraOrthographic.self, forKey: .orthographic)
        perspective = try? container.decode(GLTFCameraPerspective.self, forKey: .perspective)
        type = try container.decode(GLTFCameraType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(orthographic, forKey: .orthographic)
        try container.encode(perspective, forKey: .perspective)
        try container.encode(type, forKey: .type)
    }
}
