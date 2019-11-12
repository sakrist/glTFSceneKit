//
//  GLTFAccessor.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFAccessorComponentType: Int, RawRepresentable, Codable {
    case BYTE = 5120
    case UNSIGNED_BYTE = 5121
    case SHORT = 5122
    case UNSIGNED_SHORT = 5123
    case UNSIGNED_INT = 5125
    case FLOAT = 5126

    public var rawValue: Int {
        switch self {
        case .BYTE:
            return 5120
        case .UNSIGNED_BYTE:
            return 5121
        case .SHORT:
            return 5122
        case .UNSIGNED_SHORT:
            return 5123
        case .UNSIGNED_INT:
            return 5125
        case .FLOAT:
            return 5126
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 5120:
            self = .BYTE
        case 5121:
            self = .UNSIGNED_BYTE
        case 5122:
            self = .SHORT
        case 5123:
            self = .UNSIGNED_SHORT
        case 5125:
            self = .UNSIGNED_INT
        case 5126:
            self = .FLOAT
        default:
            return nil
        }
    }

}

@objc public enum GLTFAccessorType: Int, RawRepresentable, Codable {
    case SCALAR
    case VEC2
    case VEC3
    case VEC4
    case MAT2
    case MAT3
    case MAT4
    
    
    public var rawIntValue: Int {
        switch self {
        case .SCALAR:
            return 0
        case .VEC2:
            return 1
        case .VEC3:
            return 2
        case .VEC4:
            return 3
        case .MAT2:
            return 4
        case .MAT3:
            return 5
        case .MAT4:
            return 6
        }
    }

    public var rawValue: String {
        switch self {
        case .SCALAR:
            return "SCALAR"
        case .VEC2:
            return "VEC2"
        case .VEC3:
            return "VEC3"
        case .VEC4:
            return "VEC4"
        case .MAT2:
            return "MAT2"
        case .MAT3:
            return "MAT3"
        case .MAT4:
            return "MAT4"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "SCALAR":
            self = .SCALAR
        case "VEC2":
            self = .VEC2
        case "VEC3":
            self = .VEC3
        case "VEC4":
            self = .VEC4
        case "MAT2":
            self = .MAT2
        case "MAT3":
            self = .MAT3
        case "MAT4":
            self = .MAT4
        default:
            return nil
        }
    }

}


/// A typed view into a bufferView.  A bufferView contains raw binary data.  An accessor provides a typed view into a bufferView or a subset of a bufferView similar to how WebGL's `vertexAttribPointer()` defines an attribute in a buffer.
@objcMembers
open class GLTFAccessor : NSObject, Codable {
    /// The index of the bufferView.
    public var bufferView:Int?

    /// The offset relative to the start of the bufferView in bytes.
    public var byteOffset:Int

    /// The datatype of components in the attribute.
    public var componentType:GLTFAccessorComponentType

    /// The number of attributes referenced by this accessor.
    public var count:Int

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// Maximum value of each component in this attribute.
    public var max:[Double]?

    /// Minimum value of each component in this attribute.
    public var min:[Double]?

    /// The user-defined name of this object.
    public var name:String?

    /// Specifies whether integer data values should be normalized.
    public var normalized:Bool = false

    /// Sparse storage of attributes that deviate from their initialization value.
    public var sparse:GLTFAccessorSparse?

    /// Specifies if the attribute is a scalar, vector, or matrix.
    public var type:GLTFAccessorType

    private enum CodingKeys: String, CodingKey {
        case bufferView
        case byteOffset
        case componentType
        case count
        case extensions
        case extras
        case max
        case min
        case name
        case normalized
        case sparse
        case type
    }
    
    
    public init (bufferView:Int?,
                 byteOffset:Int,
                 componentType:GLTFAccessorComponentType,
                 count:Int,
                 type:GLTFAccessorType) {
        self.bufferView = bufferView
        self.byteOffset = byteOffset
        self.componentType = componentType
        self.count = count
        self.type = type
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bufferView = try? container.decode(Int.self, forKey: .bufferView)
        do {
            byteOffset = try container.decode(Int.self, forKey: .byteOffset)
        } catch {
            byteOffset = 0
        }
        componentType = try container.decode(GLTFAccessorComponentType.self, forKey: .componentType)
        count = try container.decode(Int.self, forKey: .count)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        max = try? container.decode([Double].self, forKey: .max)
        min = try? container.decode([Double].self, forKey: .min)
        name = try? container.decode(String.self, forKey: .name)
        do {
            normalized = try container.decode(Bool.self, forKey: .normalized)
        } catch {
            normalized = false
        }
        sparse = try? container.decode(GLTFAccessorSparse.self, forKey: .sparse)
        type = try container.decode(GLTFAccessorType.self, forKey: .type)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bufferView, forKey: .bufferView)
        try container.encode(byteOffset, forKey: .byteOffset)
        try container.encode(componentType, forKey: .componentType)
        try container.encode(count, forKey: .count)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(max, forKey: .max)
        try container.encode(min, forKey: .min)
        try container.encode(name, forKey: .name)
        try container.encode(normalized, forKey: .normalized)
        try container.encode(sparse, forKey: .sparse)
        try container.encode(type, forKey: .type)
    }
}
