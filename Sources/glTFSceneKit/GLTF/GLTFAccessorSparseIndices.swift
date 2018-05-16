//
//  GLTFAccessorSparseIndices.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFAccessorSparseIndicesComponentType: Int, RawRepresentable, Codable {
    case UNSIGNED_BYTE = 5121
    case UNSIGNED_SHORT = 5123
    case UNSIGNED_INT = 5125

    public var rawValue: Int {
        switch self {
        case .UNSIGNED_BYTE:
            return 5121
        case .UNSIGNED_SHORT:
            return 5123
        case .UNSIGNED_INT:
            return 5125
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 5121:
            self = .UNSIGNED_BYTE
        case 5123:
            self = .UNSIGNED_SHORT
        case 5125:
            self = .UNSIGNED_INT
        default:
            return nil
        }
    }

}


/// Indices of those attributes that deviate from their initialization value.
@objcMembers
open class GLTFAccessorSparseIndices : NSObject, Codable {
    /// The index of the bufferView with sparse indices. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target.
    public var bufferView:Int

    /// The offset relative to the start of the bufferView in bytes. Must be aligned.
    public var byteOffset:Int

    /// The indices data type.
    public var componentType:GLTFAccessorSparseIndicesComponentType

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    private enum CodingKeys: String, CodingKey {
        case bufferView
        case byteOffset
        case componentType
        case extensions
        case extras
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bufferView = try container.decode(Int.self, forKey: .bufferView)
        do {
            byteOffset = try container.decode(Int.self, forKey: .byteOffset)
        } catch {
            byteOffset = 0
        }
        componentType = try container.decode(GLTFAccessorSparseIndicesComponentType.self, forKey: .componentType)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bufferView, forKey: .bufferView)
        try container.encode(byteOffset, forKey: .byteOffset)
        try container.encode(componentType, forKey: .componentType)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
    }
}
