//
//  GLTFNode.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// A node in the node hierarchy.  When the node contains `skin`, all `mesh.primitives` must contain `JOINTS_0` and `WEIGHTS_0` attributes.  A node can have either a `matrix` or any combination of `translation`/`rotation`/`scale` (TRS) properties. TRS properties are converted to matrices and postmultiplied in the `T * R * S` order to compose the transformation matrix; first the scale is applied to the vertices, then the rotation, and then the translation. If none are provided, the transform is the identity. When a node is targeted for animation (referenced by an animation.channel.target), only TRS properties may be present; `matrix` will not be present.
@objcMembers
open class GLTFNode: NSObject, Codable {
    /// The index of the camera referenced by this node.
    public var camera: Int?

    /// The indices of this node's children.
    public var children: [Int]?

    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// A floating-point 4x4 transformation matrix stored in column-major order.
    public var matrix: [Double]

    /// The index of the mesh in this node.
    public var mesh: Int?

    /// The user-defined name of this object.
    public var name: String?

    /// The node's unit quaternion rotation in the order (x, y, z, w), where w is the scalar.
    public var rotation: [Double]

    /// The node's non-uniform scale, given as the scaling factors along the x, y, and z axes.
    public var scale: [Double]

    /// The index of the skin referenced by this node.
    public var skin: Int?

    /// The node's translation along the x, y, and z axes.
    public var translation: [Double]

    /// The weights of the instantiated Morph Target. Number of elements must match number of Morph Targets of used mesh.
    public var weights: [Double]?

    private enum CodingKeys: String, CodingKey {
        case camera
        case children
        case extensions
        case extras
        case matrix
        case mesh
        case name
        case rotation
        case scale
        case skin
        case translation
        case weights
    }

    public override init() {
        matrix = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        rotation = [0, 0, 0, 1]
        scale = [1, 1, 1]
        translation = [0, 0, 0]
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        camera = try? container.decode(Int.self, forKey: .camera)
        children = try? container.decode([Int].self, forKey: .children)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        do {
            matrix = try container.decode([Double].self, forKey: .matrix)
        } catch {
            matrix = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]
        }
        mesh = try? container.decode(Int.self, forKey: .mesh)
        name = try? container.decode(String.self, forKey: .name)
        do {
            rotation = try container.decode([Double].self, forKey: .rotation)
        } catch {
            rotation = [0, 0, 0, 1]
        }
        do {
            scale = try container.decode([Double].self, forKey: .scale)
        } catch {
            scale = [1, 1, 1]
        }
        skin = try? container.decode(Int.self, forKey: .skin)
        do {
            translation = try container.decode([Double].self, forKey: .translation)
        } catch {
            translation = [0, 0, 0]
        }
        weights = try? container.decode([Double].self, forKey: .weights)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(camera, forKey: .camera)
        try container.encode(children, forKey: .children)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(matrix, forKey: .matrix)
        try container.encode(mesh, forKey: .mesh)
        try container.encode(name, forKey: .name)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scale, forKey: .scale)
        try container.encode(skin, forKey: .skin)
        try container.encode(translation, forKey: .translation)
        try container.encode(weights, forKey: .weights)
    }
}
