//
//  GLTF+Extension.swift
//  
//
//  Created by Volodymyr Boichentsov on 13/10/2017.
//  Copyright © 2017 Volodymyr Boichentsov. All rights reserved.
//

import Foundation
import SceneKit
import Draco

let dracoExtensionKey = "KHR_draco_mesh_compression"
let compressedTextureExtensionKey = "3D4M_compressed_texture"

extension GLTF {

    private static var associationMap = [String: Any]()
    private struct Keys {
        static var cache_nodes:String = "cache_nodes"
        static var cache_materials:String = "cache_materials"
        static var animation_duration:String = "animation_duration"
        static var _directory:String = "directory"
        static var _cameraCreated:String = "_cameraCreated"
    }
    
    private var cache_nodes:[SCNNode?]? {
        get { return GLTF.associationMap[Keys.cache_nodes] as? [SCNNode?] }
        set { if newValue != nil { GLTF.associationMap[Keys.cache_nodes] = newValue } }
    }
    
    private var cache_materials:[SCNMaterial?]? {
        get { return GLTF.associationMap[Keys.cache_materials] as? [SCNMaterial?] }
        set { if newValue != nil { GLTF.associationMap[Keys.cache_materials] = newValue } }
    }
    
    private var animationDuration:Double {
        get { return (GLTF.associationMap[Keys.animation_duration] as? Double) ?? 0 }
        set { GLTF.associationMap[Keys.animation_duration] = newValue }
    }
    
    private var directory:String {
        get { return (GLTF.associationMap[Keys._directory] ?? "") as! String  }
        set { GLTF.associationMap[Keys._directory] = newValue }
    }

    private var cameraCreated:Bool {
        get { return (GLTF.associationMap[Keys._cameraCreated] as? Bool) ?? false }
        set { GLTF.associationMap[Keys._cameraCreated] = newValue }
    }
    
    private var view:SCNView? {
        get { return (GLTF.associationMap["view"] as? SCNView)  }
        set { GLTF.associationMap["view"] = newValue }
    }
    
    /// Convert GLTF to SceneKit scene. 
    ///
    /// - Parameter directory: location of other related resources to gltf
    /// - Returns: instance of Scene
    @objc
    open func convertToScene(view:SCNView, directoryPath:String) -> SCNScene? {
        self.view = view
        
        if (self.extensionsUsed != nil) {
            for key in self.extensionsUsed! {
                if key == dracoExtensionKey {
                    
                } else {
                    print("Used `\(key)` extension is not supported!")
                }
            }
        }
        
        if (self.extensionsRequired != nil) {
            for key in self.extensionsRequired! {
                if key == dracoExtensionKey {
                    
                } else {
                    print("Required `\(key)` extension is not supported!")
                    return nil
                }
            }
        }
        
        self.directory = directoryPath
        let scene:SCNScene = SCNScene.init()
        if self.scenes != nil && self.scene != nil {
            let sceneGlTF = self.scenes![(self.scene)!]
            if let sceneName = sceneGlTF.name {
                scene.setAttribute(sceneName, forKey: "name")
            }
            
            self.cache_nodes = [SCNNode?](repeating: nil, count: (self.nodes?.count)!)
            self.cache_materials = [SCNMaterial?](repeating: nil, count: (self.materials?.count)!)
            
            // parse nodes
            for nodeIndex in sceneGlTF.nodes! {
                let node = buildNode(index:nodeIndex)
                scene.rootNode.addChildNode(node)
                
                node.runAction(SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 0))
            }
            
            parseAnimations()
            
            // TODO: replace with other internal objects
            cleanExtras()
            
            // remove cache information
            GLTF.associationMap = [String: Any]()
        }
        
        return scene
    }
    
    fileprivate func parseAnimations() {
        if self.animations != nil {
            for animation in self.animations! {
                for channel in animation.channels {
                    let sampler = animation.samplers[channel.sampler]
                    do {
                        try constructAnimation(sampler: sampler, target:channel.target)
                    } catch {
                        print(error)
                    }
                }
            }
        }
        
        for node in self.cache_nodes! {
            let group = node?.value(forUndefinedKey: "group") as? CAAnimationGroup
            if group != nil && self.animationDuration != 0 {
                group?.duration = self.animationDuration
            }
        }
    }
    
    fileprivate func constructAnimation(sampler:GLTFAnimationSampler, target:GLTFAnimationChannelTarget ) throws {
        
        let node:SCNNode = self.cache_nodes![target.node!]!
        
        let accessorInput = self.accessors![sampler.input]
        let accessorOutput = self.accessors![sampler.output]
        
        let keyTimesFloat = loadAccessorAsArray(accessorInput) as! [Float]
        let duration = Double(keyTimesFloat.last!)
        let f_duration = Float(duration)
        let keyTimes: [NSNumber] = keyTimesFloat.map { NSNumber(value: $0 / f_duration ) }
        
        let values_ = loadAccessorAsArray(accessorOutput)
        
        var groupDuration:Double = 0
        
        var caanimations:[CAAnimation] = [CAAnimation]() 
        if target.path == .weights {
            let weightPaths = node.value(forUndefinedKey: "weightPaths") as? [String]
                        
            groupDuration = duration
            
            var keyAnimations = [CAKeyframeAnimation]()
            for path in weightPaths! {
                let animation = CAKeyframeAnimation()
                animation.keyPath = path
                animation.keyTimes = keyTimes
                animation.duration = duration
                keyAnimations.append(animation)
            }
                        
            let step = keyAnimations.count
            let dataLength = values_.count / step
            guard dataLength == keyTimes.count else {
                throw "data count mismatch: \(dataLength) != \(keyTimes.count)"
            }
            
            for i in 0..<keyAnimations.count {
                var valueIndex = i
                var v = [NSNumber]()
                v.reserveCapacity(dataLength)
                for _ in 0..<dataLength {
                    v.append(NSNumber(value: (values_[valueIndex] as! Float) ))
                    valueIndex += step
                }
                keyAnimations[i].values = v
            }
            
            caanimations = keyAnimations
            
        } else {
            let keyFrameAnimation = CAKeyframeAnimation()
            
            self.animationDuration = max(self.animationDuration, duration)
            
            keyFrameAnimation.keyPath = target.path.scn()
            keyFrameAnimation.keyTimes = keyTimes
            keyFrameAnimation.values = values_
            keyFrameAnimation.repeatCount = .infinity
            keyFrameAnimation.duration = duration
            
            caanimations.append(keyFrameAnimation)
            
            groupDuration = self.animationDuration
        }
        
        let group = (node.value(forUndefinedKey: "group") as? CAAnimationGroup) ?? CAAnimationGroup()
        node.setValue(group, forUndefinedKey: "group")
        var animations = group.animations ?? []
        animations.append(contentsOf: caanimations)
        group.animations = animations 
        group.duration = groupDuration
        group.repeatCount = .infinity
        node.addAnimation(group, forKey: target.path.rawValue)
    }
    
    // MARK: - Nodes
    
    fileprivate func buildNode(index:Int) -> SCNNode {
        let scnNode = SCNNode()
        if self.nodes != nil {
            let node = self.nodes![index]
            scnNode.name = node.name
            
            // Get camera, if it has reference on any. 
            constructCamera(node, scnNode)
            
            // convert meshes if any exists in gltf node
            geometryNode(node, scnNode)
            
            // construct animation paths
            var weightPaths = [String]()
            for i in 0..<scnNode.childNodes.count {
                let primitive = scnNode.childNodes[i]
                if let morpher = primitive.morpher {
                    for j in 0..<morpher.targets.count {
                        let path = "childNodes[\(i)].morpher.weights[\(j)]"
                        weightPaths.append(path)
                    }
                }
            }
            scnNode.setValue(weightPaths, forUndefinedKey: "weightPaths")
            
            // load skin if any reference exists
            if let skin = node.skin {
                loadSkin(skin, scnNode)
            }
            
            // bake all transformations into one mtarix
            scnNode.transform = bakeTransformationMatrix(node)
            
            self.cache_nodes?[index] = scnNode
            
            if let children = node.children {
                for i in children {
                    let subSCNNode = buildNode(index:i)
                    scnNode.addChildNode(subSCNNode)
                }
            }
        }
        return scnNode
    }
    
    fileprivate func bakeTransformationMatrix(_ node:GLTFNode) -> SCNMatrix4 {
        let rotation = GLKMatrix4MakeWithQuaternion(GLKQuaternion.init(q: (Float(node.rotation[0]), Float(node.rotation[1]), Float(node.rotation[2]), Float(node.rotation[3]))))
        var matrix = SCNMatrix4.init(array:node.matrix)
        matrix = SCNMatrix4Translate(matrix, SCNFloat(node.translation[0]), SCNFloat(node.translation[1]), SCNFloat(node.translation[2]))
        matrix = SCNMatrix4Mult(matrix, SCNMatrix4FromGLKMatrix4(rotation)) 
        matrix = SCNMatrix4Scale(matrix, SCNFloat(node.scale[0]), SCNFloat(node.scale[1]), SCNFloat(node.scale[2]))
        return matrix
    }
    
    fileprivate func constructCamera(_ node:GLTFNode, _ scnNode:SCNNode) {
        if let cameraIndex = node.camera {
            scnNode.camera = SCNCamera()
            if self.cameras != nil {
                let camera = self.cameras![cameraIndex]
                scnNode.camera?.name = camera.name
                switch camera.type {
                case .perspective:
                    scnNode.camera?.zNear = (camera.perspective?.znear)!
                    scnNode.camera?.zFar = (camera.perspective?.zfar)!
                    if #available(OSX 10.13, *) {
                        scnNode.camera?.fieldOfView = CGFloat((camera.perspective?.yfov)! * 180.0 / .pi)
                        scnNode.camera?.wantsDepthOfField = true
                        scnNode.camera?.motionBlurIntensity = 0.3
                    }
                    break
                case .orthographic:
                    scnNode.camera?.usesOrthographicProjection = true
                    scnNode.camera?.zNear = (camera.orthographic?.znear)!
                    scnNode.camera?.zFar = (camera.orthographic?.zfar)!
                    break
                }
            }
        }
    }  
    
    
    /// Decompress draco data
    ///
    /// - Parameter data: draco compressed data
    /// - Returns: Indices data for triangles primitives, Vertices data and stride for vertices data
    fileprivate func uncompressDracoData(_ data:Data) -> (Data, Data, Int) {
        
        var indicies:Data = Data()
        var verticies:Data = Data()
        var stride:Int = 0
        data.withUnsafeBytes {(uint8Ptr: UnsafePointer<Int8>) in
            
            var verts:UnsafeMutablePointer<Float>?
            var lengthVerts:UInt = 0
            
            var inds:UnsafeMutablePointer<UInt32>?
            var lengthInds:UInt = 0
            
            var descsriptors:UnsafeMutablePointer<DAttributeDescriptor>?
            var descsriptorsCount:UInt = 0
            
            if draco_decode(uint8Ptr, UInt(data.count), &verts, &lengthVerts, &inds, &lengthInds, &descsriptors, &descsriptorsCount) {
            
                indicies = Data.init(bytes: UnsafeRawPointer(inds)!, count: Int(lengthInds)*4)
                verticies = Data.init(bytes: UnsafeRawPointer(verts)!, count: Int(lengthVerts)*4)
                for i in 0..<descsriptorsCount {
                    stride += Int(descsriptors![Int(i)].size);
                }
                
                descsriptors?.deinitialize(count: Int(descsriptorsCount))
                descsriptors?.deallocate()
                verts?.deinitialize(count: Int(lengthVerts))
                verts?.deallocate()
                inds?.deinitialize(count: Int(lengthInds))
                inds?.deallocate()
            }
        }
        
        return (indicies, verticies, stride)
    }
    
    fileprivate func convertDracoMesh(_ dracoMesh:GLTFKHRDracoMeshCompressionExtension) -> (SCNGeometryElement?, [SCNGeometrySource]?) {
        let bufferViewIndex = dracoMesh.bufferView
        
        if (self.bufferViews?.count)! <= bufferViewIndex {
            return (nil, nil)
        }
        
        let bufferView = self.bufferViews![bufferViewIndex]
        if self.buffers != nil && bufferView.buffer < self.buffers!.count { 
            let buffer = self.buffers![bufferView.buffer]
            if let data = buffer.data(inDirectory:self.directory, cache: false) {
                                    
//                    let start = bufferView.byteOffset
//                    let end = (bufferView.byteLength != nil) ? bufferView.byteLength! : data.count 
//                    
//                    if start != 0 && end != data.count {
//                        data = data.subdata(in: start..<end)
//                    }
                
                let (indicesData, verticies, stride) = self.uncompressDracoData(data)
        
                let primitiveCount = (indicesData.count / 12)
                
                let element = SCNGeometryElement.init(data: indicesData,
                                               primitiveType: .triangles,
                                               primitiveCount: primitiveCount,
                                               bytesPerIndex: 4)
                
                
                let byteStride = (bufferView.byteStride != nil) ? bufferView.byteStride! : (stride * 4)
                let count = verticies.count / byteStride
                var byteOffset = 0
                
                var geometrySources = [SCNGeometrySource]()
                                        
                // sort attributes
                var sortedAttributes:[String] = [String](repeating: "", count: dracoMesh.attributes.count)
                for pair in dracoMesh.attributes {
                    sortedAttributes[pair.value] = pair.key
                }
                
                for key in sortedAttributes {
                    // convert string semantic to SceneKit enum type 
                    let semantic = self.sourceSemantic(name:key)
                    
                    let geometrySource = SCNGeometrySource.init(data: verticies, 
                                                                semantic: semantic, 
                                                                vectorCount: count, 
                                                                usesFloatComponents: true, 
                                                                componentsPerVector: ((semantic == .texcoord) ? 2 : 3) , 
                                                                bytesPerComponent: 4, 
                                                                dataOffset: byteOffset, 
                                                                dataStride: byteStride)
                    geometrySources.append(geometrySource)
                    
                    byteOffset = byteOffset + ((semantic == .texcoord) ? 8 : 12)
                }
                
                return (element, geometrySources)
            } 
        }
        
        return (nil, nil)
    }
    
    /// convert glTF mesh into SCNGeometry
    ///
    /// - Parameters:
    ///   - node: gltf node
    ///   - scnNode: SceneKit node, which is going to be parent node 
    fileprivate func geometryNode(_ node:GLTFNode, _ scnNode:SCNNode) {
        if let meshIndex = node.mesh {
            if self.meshes != nil {
                let mesh = self.meshes![meshIndex]
                scnNode.name = mesh.name
                for primitive in mesh.primitives {
                    
                    var sources:[SCNGeometrySource] = [SCNGeometrySource]()
                    var elements:[SCNGeometryElement] = [SCNGeometryElement]()
                    
                    // get indices 
                    if let element = self.geometryElement(primitive) {
                        elements.append(element)   
                    }
                    
                    // get sources from attributes information
                    sources.append(contentsOf: self.loadSources(primitive.attributes))
                    
                    // check on draco extension
                    if let primitiveExtensions = primitive.extensions {
                        if let draco = primitiveExtensions[dracoExtensionKey] {
//                            let value = draco as [String : Any]
                            
                            if let json = try? JSONSerialization.data(withJSONObject: draco) {
                                if let dracoMesh = try? JSONDecoder().decode(GLTFKHRDracoMeshCompressionExtension.self, from: json) {
                                    let (dElement, dSources) = convertDracoMesh(dracoMesh)
                                    
                                    if (dElement != nil) {
                                        elements.append(dElement!)
                                    }
                                    
                                    if (dSources != nil) {
                                        sources.append(contentsOf: dSources!)
                                    }
                                    
                                }
                            }
                        }
                    }
                    
                    // create geometry
                    let geometry = SCNGeometry.init(sources: sources, elements: elements)
                    
                    if let materialIndex = primitive.material {
                        let scnMaterial = self.material(index:materialIndex)
                        geometry.materials = [scnMaterial]
                    }
                    
                    let primitiveNode = SCNNode.init(geometry: geometry)
                    
                    if let targets = primitive.targets {
                        let morpher = SCNMorpher()
                        for targetIndex in 0..<targets.count {
                            let target = targets[targetIndex]
                            let sourcesMorph = loadSources(target)
                            let geometryMorph = SCNGeometry(sources: sourcesMorph, elements: nil)
                            morpher.targets.append(geometryMorph)
                        }
                        morpher.calculationMode = .additive
                        primitiveNode.morpher = morpher
                    }
                    
                    scnNode.addChildNode(primitiveNode)
                }
            }
        }
    }
    
    fileprivate func geometryElement(_ primitive: GLTFMeshPrimitive) -> SCNGeometryElement? {
        if let indicesIndex = primitive.indices {
            if self.accessors != nil && self.bufferViews != nil {
                let accessor = self.accessors![indicesIndex]
 
                if let (indicesData, _, _) = loadData(accessor) {
                    
                    var count = accessor.count
                    
                    let primitiveType = primitive.mode.scn()
                    switch primitiveType {
                    case .triangles:
                        count = count/3
                        break
                    case .triangleStrip:
                        count = count-2
                        break
                    case .line:
                        count = count/2
                    default:
                        break
                    }
                    
                    return SCNGeometryElement.init(data: indicesData,
                                                   primitiveType: primitiveType,
                                                   primitiveCount: count,
                                                   bytesPerIndex: accessor.bytesPerElement())
                } else {
                    // here is should be errors handling
                    print("Error load geometryElement")
                }
            }
        }
        return nil
    }

    /// Convert mesh/animation attributes into SCNGeometrySource
    ///
    /// - Parameter attributes: dictionary of accessors
    /// - Returns: array of SCNGeometrySource objects
    fileprivate func loadSources(_ attributes:[String:Int]) -> [SCNGeometrySource]  {
        var geometrySources = [SCNGeometrySource]()
        for (key, accessorIndex) in attributes {
            if self.accessors != nil && self.bufferViews != nil {
                let accessor = self.accessors![accessorIndex]
                if let (data, byteStride, byteOffset) = loadData(accessor) {
                    
                    let count = accessor.count
                    
                    // convert string semantic to SceneKit enum type 
                    let semantic = self.sourceSemantic(name:key)
                    
                    let geometrySource = SCNGeometrySource.init(data: data, 
                                                                semantic: semantic, 
                                                                vectorCount: count, 
                                                                usesFloatComponents: true, 
                                                                componentsPerVector: accessor.components(), 
                                                                bytesPerComponent: accessor.bytesPerElement(), 
                                                                dataOffset: byteOffset, 
                                                                dataStride: byteStride)
                    geometrySources.append(geometrySource)
                }
            }
        }
        return geometrySources
    }
    
    // get data by accessor
    fileprivate func loadData(_ accessor:GLTFAccessor) -> (Data, Int, Int)? {
        let bufferView = self.bufferViews![accessor.bufferView!] 
        if self.buffers != nil && bufferView.buffer < self.buffers!.count { 
            let buffer = self.buffers![bufferView.buffer]
            
            var addAccessorOffset = false
            if (bufferView.byteStride == nil || accessor.components()*accessor.bytesPerElement() == bufferView.byteStride) {
                addAccessorOffset = true
            }
            
            let count = accessor.count
            let byteStride = (bufferView.byteStride == nil) ? accessor.components()*accessor.bytesPerElement() : bufferView.byteStride!
            let bytesLength = byteStride*count            
            
            if var data = buffer.data(inDirectory:self.directory) {
                
                let start = bufferView.byteOffset+((addAccessorOffset) ? accessor.byteOffset : 0)
                let end = start+bytesLength
                
                if start != 0 || end != data.count {
                    data = data.subdata(in: start..<end)
                }
                    
                let byteOffset = ((!addAccessorOffset) ? accessor.byteOffset : 0)
                return (data, byteStride, byteOffset)
            }
        }
        return nil
    }
    
    fileprivate func loadAccessorAsArray(_ accessor:GLTFAccessor) -> [Any] {
        var values = [Any]()
        if let (data, _, _) = loadData(accessor) {
            switch accessor.componentType {
            case .BYTE:
                values = data.int8Array
                break
            case .UNSIGNED_BYTE:
                values = data.uint8Array
                break
            case .SHORT:
                values = data.int16Array
                break
            case .UNSIGNED_SHORT:
                values = data.uint16Array
                break
            case .UNSIGNED_INT:
                values = data.uint32Array
                break
            case .FLOAT: 
                do {
                    switch accessor.type {
                    case .SCALAR:
                        values = data.floatArray
                        break
                    case .VEC2:
                        values = data.vec2Array 
                        break
                    case .VEC3:
                        values = data.vec3Array
                        for i in 0..<values.count {
                            values[i] = SCNVector3FromGLKVector3(values[i] as! GLKVector3)
                        }
                        break
                    case .VEC4:
                        values = data.vec4Array
                        for i in 0..<values.count {
                            values[i] = SCNVector4FromGLKVector4(values[i] as! GLKVector4)
                        }
                        break
                    case .MAT2:
                        break
                    case .MAT3:
                        break
                    case .MAT4:
                        values = data.mat4Array
                        for i in 0..<values.count {
                            values[i] = SCNMatrix4FromGLKMatrix4(values[i] as! GLKMatrix4)
                        }
                        break
                    }
                }
                break
            }
        } 
        return values
    }
    
    // convert attributes name to SceneKit semantic
    fileprivate func sourceSemantic(name:String) -> SCNGeometrySource.Semantic {
        switch name {
        case "POSITION":
            return .vertex
        case "NORMAL":
            return .normal
        case "TANGENT":
            return .tangent
        case "COLOR":
            return .color
        case "TEXCOORD_0", "TEXCOORD_1", "TEXCOORD_2", "TEXCOORD_3", "TEXCOORD_4":
            return .texcoord
        case "JOINTS_0":
            return .boneIndices
        case "WEIGHTS_0":
            return .boneWeights
        default:
            return .vertex
        }
    }
    
    fileprivate func loadSkin(_ skin:Int, _ scnNode:SCNNode) {
        // TODO: implement
    }
    
    
    // MARK: - Material
    
    // load material by index
    fileprivate func material(index:Int) -> SCNMaterial {
        var scnMaterial_ = self.cache_materials![index]
        if scnMaterial_ == nil {
            scnMaterial_ = SCNMaterial() 
        }
        let scnMaterial = scnMaterial_!
        if self.materials != nil && index < (self.materials?.count)! {
            let material = self.materials![index]
            scnMaterial.name = material.name
            scnMaterial.isDoubleSided = material.doubleSided
            
            if let pbr = material.pbrMetallicRoughness {
                scnMaterial.lightingModel = .physicallyBased
                if let baseTextureInfo = pbr.baseColorTexture {
                    self.loadTexture(index:baseTextureInfo.index, property: scnMaterial.diffuse)
                } else {
                    let color = (pbr.baseColorFactor.count < 4) ? [1, 1, 1, 1] : (pbr.baseColorFactor)
                    scnMaterial.diffuse.contents = ColorClass(red: CGFloat(color[0]), green: CGFloat(color[1]), blue: CGFloat(color[2]), alpha: CGFloat(color[3]))
                }
                
                if let metallicRoughnessTextureInfo = pbr.metallicRoughnessTexture {
                    if #available(OSX 10.13, *) {
                        scnMaterial.metalness.textureComponents = .blue
                        scnMaterial.roughness.textureComponents = .green
                        self.loadTexture(index:metallicRoughnessTextureInfo.index, property: scnMaterial.metalness)
                        self.loadTexture(index:metallicRoughnessTextureInfo.index, property: scnMaterial.roughness)
                    } else {
                        // Fallback on earlier versions
                        if self.textures != nil &&  metallicRoughnessTextureInfo.index < (self.textures?.count)! {
                            let texture = self.textures![metallicRoughnessTextureInfo.index]
                            if texture.source != nil {
                                
                                loadSampler(sampler:texture.sampler, property: scnMaterial.roughness)
                                loadSampler(sampler:texture.sampler, property: scnMaterial.metalness)
                                
                                let image = self.image(byIndex:texture.source!)
                                if let images = try? image?.channels() {
                                    scnMaterial.roughness.contents = images?[1]
                                    scnMaterial.metalness.contents = images?[2]
                                }
                            }
                        }
                    }
                    
                } else {
                    scnMaterial.metalness.intensity = CGFloat(pbr.metallicFactor)
                    scnMaterial.roughness.intensity = CGFloat(pbr.roughnessFactor)
                }
            }

            if let normalTextureInfo = material.normalTexture {
                self.loadTexture(index: normalTextureInfo.index!, property: scnMaterial.normal)
            }

            if let occlusionTextureInfo = material.occlusionTexture {
                self.loadTexture(index: occlusionTextureInfo.index!, property: scnMaterial.ambientOcclusion)
                scnMaterial.ambientOcclusion.intensity = CGFloat(occlusionTextureInfo.strength)
            }
            
            if let emissiveTextureInfo = material.emissiveTexture {
                self.loadTexture(index: emissiveTextureInfo.index, property: scnMaterial.emission)
            } else {
                let color = (material.emissiveFactor.count < 3) ? [1, 1, 1] : (material.emissiveFactor)
                scnMaterial.emission.contents = SCNVector4Make(SCNFloat(color[0]), SCNFloat(color[1]), SCNFloat(color[2]), 1.0)
            }
        }
        
        return scnMaterial
    }
    
    // get image by index
    fileprivate func image(byIndex index:Int) -> ImageClass? {
        if self.images != nil {
            let image = self.images![index]
            return image.image(inDirectory:self.directory)
        }
        return nil
    }
    
    
    /// Load texture by index.
    ///
    /// - Parameters:
    ///   - index: index of GLTFTexture in textures
    ///   - property: material's property
    fileprivate func loadTexture(index:Int, property:SCNMaterialProperty) {
        if self.textures != nil && index < self.textures!.count {
            let texture = self.textures![index]
            
            loadSampler(sampler:texture.sampler, property: property)
            
            if texture.extras != nil && texture.extras!["texture"] != nil {
                property.contents = texture.extras!["texture"]
                return
            }
            
            if (texture.extensions != nil) {
                if let descriptorJson = texture.extensions![compressedTextureExtensionKey] {
                    if let json = try? JSONSerialization.data(withJSONObject: descriptorJson) {
                        if let descriptor = try? JSONDecoder().decode(GLTF_3D4MCompressedTextureExtension.self, from: json) {
                            if let textureCompressed = createCompressedTexture(descriptor) {
                                texture.extras = ["texture":textureCompressed as Any]
                                property.contents = textureCompressed
                                return
                            }
                        }
                    }
                }
            }
            
            if texture.source != nil {
                let loadedImage = self.image(byIndex:texture.source!)
                texture.extras = ["texture":loadedImage as Any]
                property.contents = loadedImage
            }
        }
    }
    
    fileprivate func createCompressedTexture(_ descriptor:GLTF_3D4MCompressedTextureExtension) -> Any? {
        
        if self.view?.renderingAPI == .metal {
            
            var bytesPerRow:(Int, Int)->Int = {_,_ in return 0 }
            var pixelFormat:MTLPixelFormat = .invalid;
            var width = descriptor.width;
            var height = descriptor.height;
#if os(macOS)
            if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT1) {
                pixelFormat = .bc1_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT1) {
                pixelFormat = .bc1_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 8 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT3) {
                pixelFormat = .bc2_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT3) {
                pixelFormat = .bc2_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_S3TC_DXT5) {
                pixelFormat = .bc3_rgba
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_S3TC_DXT5) {
                pixelFormat = .bc3_rgba_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_RGBA_BPTC_UNORM) {
                pixelFormat = .bc7_rgbaUnorm
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            } else if (descriptor.compression == .COMPRESSED_SRGB_ALPHA_BPTC_UNORM) {
                pixelFormat = .bc7_rgbaUnorm_srgb
                bytesPerRow = {width, height in return ((width + 3) / 4) * 16 };
            }
#endif
            
            if (pixelFormat == .invalid ) {
                print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, unsupported compression format \(descriptor.compression).")
                return nil
            }
            
            if (width == 0 || height == 0) {
                print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, inappropriate texture size.")
                return nil
            }
            
            let mipmapsCount = descriptor.sources.count
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, 
                                                                             width: width, 
                                                                             height: height, 
                                                                             mipmapped: (mipmapsCount > 1))
            textureDescriptor.mipmapLevelCount = mipmapsCount
            
            let texture = self.view?.device?.makeTexture(descriptor: textureDescriptor)
            
            for i in 0 ..< mipmapsCount {
                let bufferViewsIndex = descriptor.sources[i]
                if self.bufferViews!.count > bufferViewsIndex {
                    let bufferView = self.bufferViews![bufferViewsIndex]
                    let buffer = self.buffers![bufferView.buffer]
                    let data = buffer.data(inDirectory: self.directory, cache: false)
                    if (data == nil) {
                        print("GLTF_3D4MCompressedTextureExtension: Failed to load texture, \(String(describing: buffer.uri))")
                        return nil
                    }
                    data?.withUnsafeBytes {
                        texture?.replace(region: MTLRegionMake2D(0, 0, width, height), 
                                         mipmapLevel: i, 
                                         withBytes: $0, 
                                         bytesPerRow: bytesPerRow(width, height))
                    }
                }
                
                width = max(width >> 1, 1);
                height = max(height >> 1, 1);
            }
            return texture 
        } else {
            // TODO: implement for OpenGL  
        }
        
        return nil
    }
    
    fileprivate func loadSampler(sampler samplerIndex:Int?, property:SCNMaterialProperty) {
        if samplerIndex != nil && self.samplers != nil && samplerIndex! < self.samplers!.count {
            let sampler = self.samplers![samplerIndex!]
            property.wrapS = sampler.wrapS.scn()
            property.wrapT = sampler.wrapT.scn()
            property.magnificationFilter = sampler.magFilterScene()
            (property.minificationFilter, property.mipFilter)  = sampler.minFilterScene()
        }
    }
    
    
    fileprivate func cleanExtras() {
        if self.buffers != nil {
            for buffer in self.buffers! {
                buffer.extras = nil
            }
        }
        
        if self.images != nil {
            for image in self.images! {
                image.extras = nil
            }
        }
        if self.textures != nil {
            for texture in self.textures! {
                texture.extras = nil
            }
        }
        
        self.cache_nodes?.removeAll()
    }
}

extension GLTFSampler {
    fileprivate func magFilterScene() -> SCNFilterMode {
        if self.magFilter != nil {
            return (self.magFilter?.scn())!
        }
        return .none
    }
    
    fileprivate func minFilterScene() -> (SCNFilterMode, SCNFilterMode) {
        if self.minFilter != nil {
            return (self.minFilter?.scn())!
        }
        return (.none, .none)
    }
}

extension GLTFSamplerMagFilter {
    fileprivate func scn() -> SCNFilterMode {
        switch self {
        case .LINEAR:
            return .linear
        case .NEAREST:
            return .nearest
        }
    }
}

extension GLTFSamplerMinFilter {
    fileprivate func scn() -> (SCNFilterMode, SCNFilterMode) {
        switch self {
        case .LINEAR:
            return (.linear, .none)
        case .NEAREST:
            return (.nearest, .none)
        case .LINEAR_MIPMAP_LINEAR:
            return (.linear, .linear)
        case .NEAREST_MIPMAP_NEAREST:
            return (.nearest, .nearest)
        case .LINEAR_MIPMAP_NEAREST:
            return (.linear, .nearest)
        case .NEAREST_MIPMAP_LINEAR:
            return (.nearest, .linear)
        }
    }
}

extension GLTFSamplerWrapS {
    fileprivate func scn() -> SCNWrapMode {
        switch self {
        case .CLAMP_TO_EDGE:
            return .clampToBorder
        case .REPEAT:
            return .repeat
        case .MIRRORED_REPEAT:
            return .mirror
        }
    }
}

extension GLTFSamplerWrapT {
    fileprivate func scn() -> SCNWrapMode {
        switch self {
        case .CLAMP_TO_EDGE:
            return .clampToBorder
        case .REPEAT:
            return .repeat
        case .MIRRORED_REPEAT:
            return .mirror
        }
    }
}

extension GLTFBuffer {
    
    fileprivate func data(inDirectory directory:String, cache:Bool = true) -> Data? {
        var data:Data?
        if self.extras != nil {
            data = self.extras!["data"] as? Data
        }
        if data == nil {
            do {
                data = try loadURI(uri: self.uri!, inDirectory: directory)
                if (cache) {
                    self.extras = ["data": data as Any]
                }
            } catch {
                print(error)
            }
        }
        return data
    } 
}

extension GLTFImage {
    fileprivate func image(inDirectory directory:String) -> ImageClass? {
        var image:ImageClass?
        if self.extras != nil {
            image = self.extras!["image"] as? ImageClass
        }
        if image == nil {
            do {
                if let imageData = try loadURI(uri: self.uri!, inDirectory: directory) {
                    image = ImageClass.init(data: imageData)
                }
                self.extras = ["image": image as Any]
            } catch {
                print(error)
            }
        }
        return image
    } 
}

extension GLTFAccessor {
    fileprivate func components() -> Int {
        switch type {
        case .SCALAR:
            return 1
        case .VEC2:
            return 2
        case .VEC3:
            return 3
        case .VEC4, .MAT2:
            return 4
        case .MAT3:
            return 9
        case .MAT4:
            return 16
        }
    }
    
    fileprivate func bytesPerElement() -> Int {
        switch componentType {
        case .UNSIGNED_BYTE, .BYTE:
            return 1
        case .UNSIGNED_SHORT, .SHORT:
            return 2
        default:
            return 4
        }
    }
}

extension GLTFMeshPrimitiveMode {
    fileprivate func scn() -> SCNGeometryPrimitiveType {
        switch self {
        case .POINTS:
            return .point
        case .LINES, .LINE_LOOP, .LINE_STRIP:
            return .line
        case .TRIANGLE_STRIP:
            return .triangleStrip
        case .TRIANGLES:
            return .triangles
        default:
            return .triangles
        }
    }
}

extension GLTFAnimationChannelTargetPath {
    fileprivate func scn() -> String {
        switch self {
        case .translation:
            return "position"
        case .rotation:
            return "orientation"
        case .scale:
            return self.rawValue
        case .weights:
            return self.rawValue
        }
    }
}

