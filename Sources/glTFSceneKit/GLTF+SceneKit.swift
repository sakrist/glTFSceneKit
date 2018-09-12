//
//  GLTF+Extension.swift
//  
//
//  Created by Volodymyr Boichentsov on 13/10/2017.
//  Copyright © 2017 Volodymyr Boichentsov. All rights reserved.
//

import Foundation
import SceneKit
import os

let log_scenekit = OSLog(subsystem: "org.glTFSceneKit", category: "scene")

let dracoExtensionKey = "KHR_draco_mesh_compression"
let compressedTextureExtensionKey = "3D4M_compressed_texture"
let supportedExtensions = [dracoExtensionKey, compressedTextureExtensionKey]


struct ConvertionProgressMask : OptionSet {
    let rawValue: Int
    
    static let nodes  = ConvertionProgressMask(rawValue: 1 << 1)
    static let textures = ConvertionProgressMask(rawValue: 1 << 2)
    static let animations  = ConvertionProgressMask(rawValue: 1 << 3)
    
    static func all() -> ConvertionProgressMask {
        return [.nodes, .textures, .animations]
    }
}

extension GLTF {

    struct Keys {
        static var cache_nodes = "cache_nodes"
        static var animation_duration = "animation_duration"
        static var resource_loader = "resource_loader"
        static var load_canceled = "load_canceled"
        static var completion_handler = "completion_handler"
        static var scnview = "scnview"
        static var nodesDispatchGroup = "nodesDispatchGroup"
        static var convertionProgress = "convertionProgressMask"
    }
    
    /// Status will be true if `cancel` was call.
    @objc open private(set) var isCancelled:Bool {
        get { return (objc_getAssociatedObject(self, &Keys.load_canceled) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Keys.load_canceled, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    var cache_nodes:[SCNNode?]? {
        get { return objc_getAssociatedObject(self, &Keys.cache_nodes) as? [SCNNode?] }
        set { objc_setAssociatedObject(self, &Keys.cache_nodes, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var convertionProgressMask:ConvertionProgressMask {
        get {
            var p = objc_getAssociatedObject(self, &Keys.convertionProgress)
            if p == nil {
                p = ConvertionProgressMask.init(rawValue: 0)
                objc_setAssociatedObject(self, &Keys.convertionProgress, p, .OBJC_ASSOCIATION_RETAIN)
            }
            return p as! ConvertionProgressMask 
        }
        set { objc_setAssociatedObject(self, &Keys.convertionProgress, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    var renderer:SCNSceneRenderer? {
        get { return objc_getAssociatedObject(self, &Keys.scnview) as? SCNSceneRenderer }
        set { objc_setAssociatedObject(self, &Keys.scnview, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    var _completionHandler:((Error?) -> Void) {
        get { return (objc_getAssociatedObject(self, &Keys.completion_handler) as? ((Error?) -> Void) ?? {_ in }) }
        set { objc_setAssociatedObject(self, &Keys.completion_handler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var nodesDispatchGroup:DispatchGroup {
        get { 
            if let d = objc_getAssociatedObject(self, &Keys.nodesDispatchGroup) {
                return d as! DispatchGroup
            } 
            let group = DispatchGroup()
            objc_setAssociatedObject(self, &Keys.nodesDispatchGroup, group, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return group
        }
        set { objc_setAssociatedObject(self, &Keys.nodesDispatchGroup, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    
    
    /// Convert glTF object to SceneKit scene. 
    ///
    /// - Parameter scene: Optional parameter. If property is set then loaded model will be add to existing objects in scene.
    /// - Parameter view: Required for Metal. But optional for OpenGL rendering.
    /// - Parameter directoryPath: location to others related resources of glTF.
    /// - Parameter multiThread: By default model will be load in multiple threads.
    /// - Parameter completionHandler: Execute completion block once model fully loaded. If multiThread parameter set to true, then scene will be returned soon as possible and completion block will be executed later, after all textures load. 
    /// - Returns: instance of Scene
    @objc open func convert(to scene:SCNScene = SCNScene.init(),
                             renderer:SCNSceneRenderer? = nil, 
                             directoryPath:String? = nil, 
                             multiThread:Bool = true, 
                             hidden:Bool = false,
                             completionHandler: @escaping ((Error?) -> Void) = {_ in } ) -> SCNScene? {

        if (self.extensionsUsed != nil) {
            for key in self.extensionsUsed! {
                if !supportedExtensions.contains(key) {
                    completionHandler("Used `\(key)` extension is not supported!")
                    return nil
                }
            }
        }
        
        if (self.extensionsRequired != nil) {
            for key in self.extensionsRequired! {
                if !supportedExtensions.contains(key) {
                    completionHandler("Required `\(key)` extension is not supported!")
                    return nil
                }
            }
        }
        
        self.renderer = renderer
        self._completionHandler = completionHandler
        
        if directoryPath != nil {
            self.loader.directoryPath = directoryPath!
        }
        
        // Get dispatch group for current GLTF 
        let group = self.nodesDispatchGroup
        group.enter()
        
        if self.scenes != nil && self.scene != nil {
            let sceneGlTF = self.scenes![(self.scene)!]
            if let sceneName = sceneGlTF.name {
                scene.setAttribute(sceneName, forKey: "name")
            }
            
            self.cache_nodes = [SCNNode?](repeating: nil, count: (self.nodes?.count)!)
            
            // run in multi-thread or single
            if (multiThread) {
                
                let start = Date() 
                
                // this enter is requered here in case materials has few textures
                // which loaded very quickly even before all geometries submitted for load
                let texturesGroup = TextureStorageManager.manager.group(gltf:self, true)
                
                // construct nodes tree
                _constructNodesTree(rootNode: scene.rootNode, nodes: sceneGlTF.nodes!, group: group, hidden: hidden)
                
                os_log("submit data to download %d ms", log: log_scenekit, type: .debug, Int(start.timeIntervalSinceNow * -1000))
                
                // completion
                group.notify(queue: DispatchQueue.global()) {
                    texturesGroup.leave()
                    
                    os_log("geometry loaded %d ms", log: log_scenekit, type: .debug, Int(start.timeIntervalSinceNow * -1000))
                    
                    DispatchQueue.main.async {
                        self._nodesConverted()
                    }
                }
                group.leave()
            } else {
                for nodeIndex in sceneGlTF.nodes! {
                    let scnNode = self.buildNode(nodeIndex:nodeIndex)
                    scnNode.isHidden = hidden
                    scene.rootNode.addChildNode(scnNode)
                }
                group.leave()
                self._nodesConverted()
            }
        }
        
        
        if self.isCancelled {
            return nil
        }
        
        return scene
    }
    
    @objc
    open func cancel() {
        self.isCancelled = true
        self.loader.cancelAll()
    }
    
    func _constructNodesTree(rootNode:SCNNode, nodes:[Int], group:DispatchGroup, hidden:Bool) {
        for nodeIndex in nodes {
            group.enter()
            let scnNode = SCNNode()
            scnNode.isHidden = hidden
            if let node = self.nodes?[nodeIndex] {
                scnNode.name = node.name
                
                if node.children != nil && node.children?.count != 0 {
                    _constructNodesTree(rootNode: scnNode, nodes: node.children!, group: group, hidden: hidden)
                }
                
                // create nodes up front to avoid deadlocks in multithreading
                let primitivesCount = self.meshes?[node.mesh!].primitives.count ?? 0
                for _ in 0..<primitivesCount {
                    let scnNodePrimitiveNode = SCNNode()
                    scnNode.addChildNode(scnNodePrimitiveNode)
                }
            }
            rootNode.addChildNode(scnNode)
            self.cache_nodes?[nodeIndex] = scnNode
            
            self._preloadBuffersData(nodeIndex: nodeIndex) { error in
                if error != nil {
                    print("Failed to load geometry node with error: \(error!)")
                } else {
                    _ = self.buildNode(nodeIndex: nodeIndex, scnNode: scnNode)
                }
                group.leave()
            }
        }
    }
    
     
    /// Nodes converted, start parse and create animation. 
    /// And in case no textures required to load, complete convertion from glTF to SceneKit.
    fileprivate func _nodesConverted() {
        self.convertionProgressMask.insert(.nodes)
        
        self.parseAnimations()
        // probably should be inserted some where else and call on completion of animation parse 
        self.convertionProgressMask.insert(.animations)
        
        self.nodesDispatchGroup.wait()
        
        if self.textures?.count == 0 {
            self.convertionProgressMask.insert(.textures)
        }
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted()
        }
    }
    
    func _texturesLoaded() {
        self.convertionProgressMask.insert(.textures)
        TextureStorageManager.manager.clear(gltf: self)
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted()
        }
    }
    
    /// Completion function and cache cleaning.
    func _converted() {
        os_log("convert completed", log: log_scenekit, type: .debug)
        
        // clear cache
        _completionHandler(nil)
        _completionHandler = {_ in }
        
        self.cache_nodes?.removeAll()
        
        self.clearCache()
        
    }
    
    // TODO: Collect associated buffers for node into a Set on Decode time.  
    fileprivate func _preloadBuffersData(nodeIndex:Int, completionHandler: @escaping (Error?) -> Void ) {
        
        var buffers:Set = Set<GLTFBuffer>()
        
        if let node = self.nodes?[nodeIndex] {
            if node.mesh != nil {
                if let mesh = self.meshes?[node.mesh!] {
                    for primitive in mesh.primitives {
                        // check on draco extension
                        if let dracoMesh = primitive.extensions?[dracoExtensionKey] {
                            let dracoMesh = dracoMesh as! GLTFKHRDracoMeshCompressionExtension
                            let buffer = self.buffers![self.bufferViews![dracoMesh.bufferView].buffer]
                            buffers.insert(buffer)
                        } else {
                            for (_,index) in primitive.attributes {
                                if let accessor = self.accessors?[index] {
                                    if let bufferView = accessor.bufferView {
                                        let buffer = self.buffers![self.bufferViews![bufferView].buffer]
                                        buffers.insert(buffer)
                                    }
                                }
                            }
                            if primitive.indices != nil {
                                if let accessor = self.accessors?[primitive.indices!] {
                                    if let bufferView = accessor.bufferView {
                                        let buffer = self.buffers![self.bufferViews![bufferView].buffer]
                                        buffers.insert(buffer)
                                    }
                                }
                            }
                        }
                    }
                }
            }                        
        }
        
        self.loader.load(gltf:self, resources: buffers, completionHandler:completionHandler)
    }
    
    // MARK: - Nodes
    
    fileprivate func buildNode(nodeIndex:Int, scnNode:SCNNode = SCNNode()) -> SCNNode {
        
        if let node = self.nodes?[nodeIndex] {
            
            // Get camera, if it has reference on any. 
            constructCamera(node, scnNode)
            
            // convert meshes if any exists in gltf node
            geometryNode(node, scnNode)
            
            
            // load skin if any reference exists
            if let skin = node.skin {
                loadSkin(skin, scnNode)
            }
            
            // bake all transformations into one mtarix
            scnNode.transform = bakeTransformationMatrix(node)
            
            if self.isCancelled {
                return scnNode
            }
            
            if let children = node.children {
                for i in children {     
                    let subSCNNode = self.buildNode(nodeIndex:i)
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
                    if #available(OSX 10.13, iOS 11.0, *) {
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

    
    /// convert glTF mesh into SCNGeometry
    ///
    /// - Parameters:
    ///   - node: gltf node
    ///   - scnNode: SceneKit node, which is going to be parent node 
    fileprivate func geometryNode(_ node:GLTFNode, _ scnNode:SCNNode) {
        
        if self.isCancelled {
            return
        }
        
        if let meshIndex = node.mesh {
            
            var weightPaths = [String]()
            
            if let mesh = self.meshes?[meshIndex] {
                
                var primitiveIndex = 0
                
                for primitive in mesh.primitives {
                    
                    var sources:[SCNGeometrySource] = [SCNGeometrySource]()
                    var elements:[SCNGeometryElement] = [SCNGeometryElement]()
                    
                    // get indices 
                    if let element = self.geometryElement(primitive) {
                        elements.append(element)   
                    }
                    
                    // get sources from attributes information
                    sources.append(contentsOf: self.geometrySources(primitive.attributes))
                    
                    // check on draco extension
                    if let dracoMesh = primitive.extensions?[dracoExtensionKey] {
                        let (dElement, dSources) = self.convertDracoMesh(dracoMesh as! GLTFKHRDracoMeshCompressionExtension)
                        
                        if (dElement != nil) {
                            elements.append(dElement!)
                        }
                        
                        if (dSources != nil) {
                            sources.append(contentsOf: dSources!)
                        }
                    }
                    
                    if self.isCancelled {
                        return
                    }
                    
                    // create geometry
                    let geometry = SCNGeometry.init(sources: sources, elements: elements)
                    
                    if let materialIndex = primitive.material {
                        self.loadMaterial(index:materialIndex) { scnMaterial in 
                            geometry.materials = [scnMaterial]
                        }
                    }
                    
                    let primitiveNode:SCNNode
                    if primitiveIndex < scnNode.childNodes.count  {
                        primitiveNode = scnNode.childNodes[primitiveIndex]
                        primitiveNode.geometry = geometry
                    } else {
                        primitiveNode = SCNNode.init(geometry: geometry)
                        scnNode.addChildNode(primitiveNode)
                    }
                    
                    primitiveNode.name = mesh.name
                    
                    if let transparency = primitiveNode.geometry?.firstMaterial?.transparency,
                        transparency < 1.0 {
                        primitiveNode.renderingOrder = 10
                    }
                    
                    if let targets = primitive.targets {
                        let morpher = SCNMorpher()
                        let targetsCount = targets.count 
                        for targetIndex in 0..<targetsCount {
                            let target = targets[targetIndex]
                            let sourcesMorph = geometrySources(target)
                            let geometryMorph = SCNGeometry(sources: sourcesMorph, elements: nil)
                            morpher.targets.append(geometryMorph)
                            
                            let path = "childNodes[\(primitiveIndex)].morpher.weights[\(targetIndex)]"
                            weightPaths.append(path)
                        }
                        morpher.calculationMode = .additive
                        primitiveNode.morpher = morpher
                    }
                                        
                    primitiveIndex += 1
                }
            }
            
            scnNode.setValue(weightPaths, forUndefinedKey: "weightPaths")
        }
    }
    
    fileprivate func geometryElement(_ primitive: GLTFMeshPrimitive) -> SCNGeometryElement? {
        if let indicesIndex = primitive.indices {
            if let accessor = self.accessors?[indicesIndex] {
                
                if let (indicesData, _, _) = loadAcessor(accessor) {
                    
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
    fileprivate func geometrySources(_ attributes:[String:Int]) -> [SCNGeometrySource]  {
        var geometrySources = [SCNGeometrySource]()
        for (key, accessorIndex) in attributes {
            if let accessor = self.accessors?[accessorIndex] {
                
                if let (data, byteStride, byteOffset) = loadAcessor(accessor) {
                    
                    let count = accessor.count
                    
                    // convert string semantic to SceneKit semantic type 
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
    
    
    func requestData(bufferView:Int) throws -> (GLTFBufferView, Data) {
        if let bufferView = self.bufferViews?[bufferView] {  
            let buffer = self.buffers![bufferView.buffer]
            
            if let data = try self.loader.load(gltf:self, resource: buffer) {
                return (bufferView, data)
            }
            throw "Can't load data!"
        }
        throw "Can't load data! Can't find bufferView or buffer" 
    }
    
    
    // get data by accessor
    func loadAcessor(_ accessor:GLTFAccessor) -> (Data, Int, Int)? {
        
        if accessor.bufferView == nil {
            return nil
        }
        
        if let (bufferView, data) = try? requestData(bufferView: accessor.bufferView!) { 
            
            var addAccessorOffset = false
            if (bufferView.byteStride == nil || accessor.components()*accessor.bytesPerElement() == bufferView.byteStride) {
                addAccessorOffset = true
            }
            
            let count = accessor.count
            let byteStride = (bufferView.byteStride == nil) ? accessor.components()*accessor.bytesPerElement() : bufferView.byteStride!
            let bytesLength = byteStride*count
            
            let start = bufferView.byteOffset+((addAccessorOffset) ? accessor.byteOffset : 0)
            let end = start+bytesLength
            
            var subdata = data
            if start != 0 || end != data.count {
                subdata = data.subdata(in: start..<end)
            }
            
            let byteOffset = ((!addAccessorOffset) ? accessor.byteOffset : 0)
            return (subdata, byteStride, byteOffset)
        }
        
        return nil
    }
    
    
    // convert attributes name to SceneKit semantic
    func sourceSemantic(name:String) -> SCNGeometrySource.Semantic {
        switch name {
        case "POSITION":
            return .vertex
        case "NORMAL":
            return .normal
        case "TANGENT":
            return .tangent
        case "COLOR", "COLOR_0", "COLOR_1", "COLOR_2":
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
    
    func clearCache() {
        if self.buffers != nil {
            for buffer in self.buffers! {
                buffer.data = nil
            }
        }
        
        if self.images != nil {
            for image in self.images! {
                image.image = nil
            }
        }
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



