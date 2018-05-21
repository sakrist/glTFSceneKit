//
//  GLTFMeshPrimitive.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFMeshPrimitiveMode: Int, RawRepresentable, Codable {
    case POINTS = 0
    case LINES = 1
    case LINE_LOOP = 2
    case LINE_STRIP = 3
    case TRIANGLES = 4
    case TRIANGLE_STRIP = 5
    case TRIANGLE_FAN = 6

    public var rawValue: Int {
        switch self {
        case .POINTS:
            return 0
        case .LINES:
            return 1
        case .LINE_LOOP:
            return 2
        case .LINE_STRIP:
            return 3
        case .TRIANGLES:
            return 4
        case .TRIANGLE_STRIP:
            return 5
        case .TRIANGLE_FAN:
            return 6
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .POINTS
        case 1:
            self = .LINES
        case 2:
            self = .LINE_LOOP
        case 3:
            self = .LINE_STRIP
        case 4:
            self = .TRIANGLES
        case 5:
            self = .TRIANGLE_STRIP
        case 6:
            self = .TRIANGLE_FAN
        default:
            return nil
        }
    }

    public init() {
        self = .TRIANGLES
    }
}


/// Geometry to be rendered with the given material.
@objcMembers
open class GLTFMeshPrimitive : NSObject, Codable {
    /// A dictionary object, where each key corresponds to mesh attribute semantic and each value is the index of the accessor containing attribute's data.
    public var attributes:[String: Int]

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The index of the accessor that contains the indices.
    public var indices:Int?

    /// The index of the material to apply to this primitive when rendering.
    public var material:Int?

    /// The type of primitives to render.
    public var mode:GLTFMeshPrimitiveMode

    /// An array of Morph Targets, each  Morph Target is a dictionary mapping attributes (only `POSITION`, `NORMAL`, and `TANGENT` supported) to their deviations in the Morph Target.
    public var targets:[[String: Int]]?

    private enum CodingKeys: String, CodingKey {
        case attributes
        case extensions
        case extras
        case indices
        case material
        case mode
        case targets
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attributes = try container.decode([String: Int].self, forKey: .attributes)
        extensions = try? container.decode([String: GLTFKHRDracoMeshCompressionExtension].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        indices = try? container.decode(Int.self, forKey: .indices)
        material = try? container.decode(Int.self, forKey: .material)
        do {
            mode = try container.decode(GLTFMeshPrimitiveMode.self, forKey: .mode)
        } catch {
            mode = GLTFMeshPrimitiveMode()
        }
        targets = try? container.decode([[String: Int]].self, forKey: .targets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(extensions as! [String: GLTFKHRDracoMeshCompressionExtension], forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(indices, forKey: .indices)
        try container.encode(material, forKey: .material)
        try container.encode(mode, forKey: .mode)
        try container.encode(targets, forKey: .targets)
    }
    
}

extension KeyedEncodingContainerProtocol {
    mutating func encode(_ value: [String: GLTFKHRDracoMeshCompressionExtension]?, forKey key: Key) throws {
        if value != nil {
            var container = self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
            try container.encode(value!)
        }
    }
}

