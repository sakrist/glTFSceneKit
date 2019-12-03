//
//  GLTF.swift
//
//  Created by Volodymyr Boichentsov on 23/02/2018.
//  Copyright © 2018 3D4Medical, LLC. All rights reserved.
//
//  Code generated with SchemeCompiler tool, developed by 3D4Medical.
//

import Foundation

/// The root object for a glTF asset.
@objcMembers
open class GLTF: NSObject, Codable {
    /// An array of accessors.
    public var accessors: [GLTFAccessor]?

    /// An array of keyframe animations.
    public var animations: [GLTFAnimation]?

    /// Metadata about the glTF asset.
    public var asset: GLTFAsset

    /// An array of bufferViews.
    public var bufferViews: [GLTFBufferView]?

    /// An array of buffers.
    public var buffers: [GLTFBuffer]?

    /// An array of cameras.
    public var cameras: [GLTFCamera]?

    /// Dictionary object with extension-specific objects.
    public var extensions: [String: Any]?

    /// Names of glTF extensions required to properly load this asset.
    public var extensionsRequired: [String]?

    /// Names of glTF extensions used somewhere in this asset.
    public var extensionsUsed: [String]?

    /// Application-specific data.
    public var extras: [String: Any]?

    /// An array of images.
    public var images: [GLTFImage]?

    /// An array of materials.
    public var materials: [GLTFMaterial]?

    /// An array of meshes.
    public var meshes: [GLTFMesh]?

    /// An array of nodes.
    public var nodes: [GLTFNode]?

    /// An array of samplers.
    public var samplers: [GLTFSampler]?

    /// The index of the default scene.
    public var scene: Int?

    /// An array of scenes.
    public var scenes: [GLTFScene]?

    /// An array of skins.
    public var skins: [GLTFSkin]?

    /// An array of textures.
    public var textures: [GLTFTexture]?

    private enum CodingKeys: String, CodingKey {
        case accessors
        case animations
        case asset
        case bufferViews
        case buffers
        case cameras
        case extensions
        case extensionsRequired
        case extensionsUsed
        case extras
        case images
        case materials
        case meshes
        case nodes
        case samplers
        case scene
        case scenes
        case skins
        case textures
    }

    public init(asset a: GLTFAsset) {
        asset = a
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessors = try? container.decode([GLTFAccessor].self, forKey: .accessors)
        animations = try? container.decode([GLTFAnimation].self, forKey: .animations)
        asset = try container.decode(GLTFAsset.self, forKey: .asset)
        bufferViews = try? container.decode([GLTFBufferView].self, forKey: .bufferViews)
        buffers = try? container.decode([GLTFBuffer].self, forKey: .buffers)
        cameras = try? container.decode([GLTFCamera].self, forKey: .cameras)
        extensions = try? container.decode([String: Any].self, forKey: .extensions)
        extensionsRequired = try? container.decode([String].self, forKey: .extensionsRequired)
        extensionsUsed = try? container.decode([String].self, forKey: .extensionsUsed)
        extras = try? container.decode([String: Any].self, forKey: .extras)
        images = try? container.decode([GLTFImage].self, forKey: .images)
        materials = try? container.decode([GLTFMaterial].self, forKey: .materials)
        meshes = try? container.decode([GLTFMesh].self, forKey: .meshes)
        nodes = try? container.decode([GLTFNode].self, forKey: .nodes)
        samplers = try? container.decode([GLTFSampler].self, forKey: .samplers)
        scene = try? container.decode(Int.self, forKey: .scene)
        scenes = try? container.decode([GLTFScene].self, forKey: .scenes)
        skins = try? container.decode([GLTFSkin].self, forKey: .skins)
        textures = try? container.decode([GLTFTexture].self, forKey: .textures)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessors, forKey: .accessors)
        try container.encode(animations, forKey: .animations)
        try container.encode(asset, forKey: .asset)
        try container.encode(bufferViews, forKey: .bufferViews)
        try container.encode(buffers, forKey: .buffers)
        try container.encode(cameras, forKey: .cameras)
        try container.encode(extensions, forKey: .extensions)
        try container.encode(extensionsRequired, forKey: .extensionsRequired)
        try container.encode(extensionsUsed, forKey: .extensionsUsed)
        try container.encode(extras, forKey: .extras)
        try container.encode(images, forKey: .images)
        try container.encode(materials, forKey: .materials)
        try container.encode(meshes, forKey: .meshes)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(samplers, forKey: .samplers)
        try container.encode(scene, forKey: .scene)
        try container.encode(scenes, forKey: .scenes)
        try container.encode(skins, forKey: .skins)
        try container.encode(textures, forKey: .textures)
    }
}
