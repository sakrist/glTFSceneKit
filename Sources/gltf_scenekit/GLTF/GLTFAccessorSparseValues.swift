//
//  GLTFAccessorSparseValues.swift
//
//  Created by Volodymyr Boichentsov on 09/11/2017.
//  Copyright © 2017 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// Array of size `accessor.sparse.count` times number of components storing the displaced accessor attributes pointed by `accessor.sparse.indices`.
@objcMembers
open class GLTFAccessorSparseValues : NSObject, Codable {
    /// The index of the bufferView with sparse values. Referenced bufferView can't have ARRAY_BUFFER or ELEMENT_ARRAY_BUFFER target.
    public var bufferView:Int?

    /// The offset relative to the start of the bufferView in bytes. Must be aligned.
    public var byteOffset:Int

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: [String: Codable]]?

    /// Application-specific data.
    public var extras:[String: Codable]?

    private enum CodingKeys: String, CodingKey {
        case bufferView
        case byteOffset
        case extensions
        case extras
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bufferView = try? container.decode(Int.self, forKey: .bufferView)
        do {
            byteOffset = try container.decode(Int.self, forKey: .byteOffset)
        } catch {
            byteOffset = 0
        }
        extensions = try? container.decode([String: [String: Codable]].self, forKey: .extensions)
        extras = try? container.decode([String: Codable].self, forKey: .extras)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bufferView, forKey: .bufferView)
        try container.encode(byteOffset, forKey: .byteOffset)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
    }
}
