//
//  GLTFImage.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

@objc public enum GLTFImageMimeType: Int, RawRepresentable, Codable {
    case imageJpeg
    case imagePng

    public var rawValue: String {
        switch self {
        case .imageJpeg:
            return "image/jpeg"
        case .imagePng:
            return "image/png"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "image/jpeg":
            self = .imageJpeg
        case "image/png":
            self = .imagePng
        default:
            return nil
        }
    }

}


/// Image data used to create a texture. Image can be referenced by URI or `bufferView` index. `mimeType` is required in the latter case.
@objcMembers
open class GLTFImage : NSObject, Codable {
    /// The index of the bufferView that contains the image. Use this instead of the image's uri property.
    public var bufferView:GLTFBufferView?

    /// Dictionary object with extension-specific objects.
    public var extensions:[String: Any]?

    /// Application-specific data.
    public var extras:[String: Any]?

    /// The image's MIME type.
    public var mimeType:GLTFImageMimeType?

    /// The user-defined name of this object.
    public var name:String?

    /// The uri of the image.
    public var uri:String?
    
    private enum CodingKeys: String, CodingKey {
        case bufferView
        case extensions
        case extras
        case mimeType
        case name
        case uri
    }

    public override init() { }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bufferView = try? container.decode(GLTFBufferView.self, forKey: .bufferView)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        mimeType = try? container.decode(GLTFImageMimeType.self, forKey: .mimeType)
        name = try? container.decode(String.self, forKey: .name)
        uri = try? container.decode(String.self, forKey: .uri)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bufferView, forKey: .bufferView)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extras, forKey: .extras)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(name, forKey: .name)
        try container.encode(uri, forKey: .uri)
    }
}
