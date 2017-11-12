//
//  GLTFAccessorSparse.swift
//
//  Created by Volodymyr Boichentsov on 09/11/2017.
//  Copyright © 2017 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// Sparse storage of attributes that deviate from their initialization value.
@objcMembers
open class GLTFAccessorSparse : NSObject, Codable {
    /// Number of entries stored in the sparse array.
    public var count:Int?

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: [String: Codable]]?

    /// Application-specific data.
    public var extras:[String: Codable]?

    /// Indices of those attributes that deviate from their initialization value.
    public var indices:GLTFAccessorSparseIndices?

    /// Array of size `accessor.sparse.count` times number of components storing the displaced accessor attributes pointed by `accessor.sparse.indices`.
    public var values:GLTFAccessorSparseValues?

    private enum CodingKeys: String, CodingKey {
        case count
        case extensions
        case extras
        case indices
        case values
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try? container.decode(Int.self, forKey: .count)
        extensions = try? container.decode([String: [String: Codable]].self, forKey: .extensions)
        extras = try? container.decode([String: Codable].self, forKey: .extras)
        indices = try? container.decode(GLTFAccessorSparseIndices.self, forKey: .indices)
        values = try? container.decode(GLTFAccessorSparseValues.self, forKey: .values)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(indices, forKey: .indices)
        try container.encode(values, forKey: .values)
    }
}
