//
//  GLTFKHRDracoMeshCompressionExtension.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation


/// Class template
@objcMembers
open class GLTFKHRDracoMeshCompressionExtension : NSObject, Codable {
    /// A dictionary object, where each key corresponds to an attribute and its unique attribute id stored in the compressed geometry.
    public var attributes:[String: Int]

    /// The index of the bufferView.
    public var bufferView:Int

    private enum CodingKeys: String, CodingKey {
        case attributes
        case bufferView
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        attributes = try container.decode([String: Int].self, forKey: .attributes)
        bufferView = try container.decode(Int.self, forKey: .bufferView)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(bufferView, forKey: .bufferView)
    }
}
