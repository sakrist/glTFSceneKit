//
//  GLTFBufferView.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFBufferViewTarget: Int, RawRepresentable, Codable {
    case ARRAY_BUFFER = 34962
    case ELEMENT_ARRAY_BUFFER = 34963

    public var rawValue: Int {
        switch self {
        case .ARRAY_BUFFER:
            return 34962
        case .ELEMENT_ARRAY_BUFFER:
            return 34963
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case 34962:
            self = .ARRAY_BUFFER
        case 34963:
            self = .ELEMENT_ARRAY_BUFFER
        default:
            return nil
        }
    }

}


/// A view into a buffer generally representing a subset of the buffer.
@objcMembers
open class GLTFBufferView : NSObject, Codable {
    /// The index of the buffer.
    public var buffer:Int

    /// The length of the bufferView in bytes.
    public var byteLength:Int

    /// The offset into the buffer in bytes.
    public var byteOffset:Int

    /// The stride, in bytes.
    public var byteStride:Int?

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The user-defined name of this object.
    public var name:String?

    /// The target that the GPU buffer should be bound to.
    public var target:GLTFBufferViewTarget?

    private enum CodingKeys: String, CodingKey {
        case buffer
        case byteLength
        case byteOffset
        case byteStride
        case extensions
        case extras
        case name
        case target
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        buffer = try container.decode(Int.self, forKey: .buffer)
        byteLength = try container.decode(Int.self, forKey: .byteLength)
        do {
            byteOffset = try container.decode(Int.self, forKey: .byteOffset)
        } catch {
            byteOffset = 0
        }
        byteStride = try? container.decode(Int.self, forKey: .byteStride)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        name = try? container.decode(String.self, forKey: .name)
        target = try? container.decode(GLTFBufferViewTarget.self, forKey: .target)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(buffer, forKey: .buffer)
        try container.encode(byteLength, forKey: .byteLength)
        try container.encode(byteOffset, forKey: .byteOffset)
        try container.encode(byteStride, forKey: .byteStride)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(name, forKey: .name)
        try container.encode(target, forKey: .target)
    }
}
