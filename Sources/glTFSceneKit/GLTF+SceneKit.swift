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


@objc public protocol SceneLoadingDelegate {
    @objc optional func scene(_ didLoadScene: SCNScene )
    @objc optional func scene(_ scene: SCNScene, didCreate camera: SCNCamera)
    @objc optional func scene(_ scene: SCNScene, didCreate node: SCNNode)
    @objc optional func scene(_ scene: SCNScene, didCreate material: SCNMaterial, for node: SCNNode)
}

extension GLTF {

    struct Keys {
        static var cache_nodes = "cache_nodes"
        static var animation_duration = "animation_duration"
        static var resource_loader = "resource_loader"
        static var load_canceled = "load_canceled"
        static var load_error = "load_error"
        static var completion_handler = "completion_handler"
        static var loading_delegate = "loading_delegate"
        static var loading_scene = "loading_scene"
        static var scnview = "scnview"
        static var nodesDispatchGroup = "nodesDispatchGroup"
        static var convertionProgress = "convertionProgressMask"
    }
    
    /// Status will be true if `cancel` was call.
    @objc open private(set) var isCancelled:Bool {
        get { return (objc_getAssociatedObject(self, &Keys.load_canceled) as? Bool) ?? false }
        set { objc_setAssociatedObject(self, &Keys.load_canceled, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    @objc open private(set) var errorMessage:Error? {
        get { return (objc_getAssociatedObject(self, &Keys.load_error) as? Error) }
        set { objc_setAssociatedObject(self, &Keys.load_error, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    internal private(set) var cache_nodes:[SCNNode?]? {
        get { return objc_getAssociatedObject(self, &Keys.cache_nodes) as? [SCNNode?] }
        set { objc_setAssociatedObject(self, &Keys.cache_nodes, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    internal var convertionProgressMask:ConvertionProgressMask {
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
    
    internal var renderer:SCNSceneRenderer? {
        get { return objc_getAssociatedObject(self, &Keys.scnview) as? SCNSceneRenderer }
        set { objc_setAssociatedObject(self, &Keys.scnview, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }
    
    internal var _completionHandler:((Error?) -> Void) {
        get { return (objc_getAssociatedObject(self, &Keys.completion_handler) as? ((Error?) -> Void) ?? {_ in }) }
        set { objc_setAssociatedObject(self, &Keys.completion_handler, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    internal var nodesDispatchGroup:DispatchGroup {
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
    
    internal var loadingScene:SCNScene {
        get { return (objc_getAssociatedObject(self, &Keys.loading_scene)) as! SCNScene }
        set { objc_setAssociatedObject(self, &Keys.loading_scene, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    internal var loadingDelegate:SceneLoadingDelegate? {
        get { return (objc_getAssociatedObject(self, &Keys.loading_delegate)) as? SceneLoadingDelegate }
        set { objc_setAssociatedObject(self, &Keys.loading_delegate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
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
                            loadingDelegate: SceneLoadingDelegate? = nil,
                            renderer:SCNSceneRenderer? = nil,
                            directoryPath:String? = nil,
                            multiThread:Bool = true,
                            hidden:Bool = false,
                            geometryCompletionHandler: @escaping ()->Void,
                            completionHandler: @escaping ((Error?) -> Void) = {_ in } ) -> SCNScene? {

        if (self.extensionsUsed != nil) {
//            for key in self.extensionsUsed! {
//                if !supportedExtensions.contains(key) {
//                    completionHandler("Used `\(key)` extension is not supported!")
//                    return nil
//                }
//            }
        }
        
        if (self.extensionsRequired != nil) {
            for key in self.extensionsRequired! {
                if !supportedExtensions.contains(key) {
                    completionHandler(GLTFError("Required `\(key)` extension is not supported!"))
                    return nil
                }
            }
        }
        
        self.loadingScene = scene
        self.loadingDelegate = loadingDelegate
        
        self.renderer = renderer
        self._completionHandler = completionHandler
        
        if directoryPath != nil {
            self.loader.directoryPath = directoryPath!
        }
        
        // Get dispatch group for current GLTF 
        let convertGroup = self.nodesDispatchGroup
        convertGroup.enter()
                
        if self.scenes != nil && self.scene != nil {
            let sceneGlTF = self.scenes![(self.scene)!]
            if let sceneName = sceneGlTF.name {
                scene.setAttribute(sceneName, forKey: "name")
            }
            
            self.cache_nodes = [SCNNode?](repeating: nil, count: self.nodes!.count)
            
            // run in multi-thread or single
            if (multiThread) {
                
                let start = Date() 
                
                // this enter is requered here in case materials has few textures
                // which loaded very quickly even before all geometries submitted for load
                let texturesGroup = TextureStorageManager.manager.group(gltf:self, true)
                
                // construct nodes tree
                _constructNodesTree(rootNode: scene.rootNode, nodes: sceneGlTF.nodes!, group: convertGroup, hidden: hidden)
                
                os_log("submit data to download %d ms", log: log_scenekit, type: .debug, Int(start.timeIntervalSinceNow * -1000))
                
                // completion
                convertGroup.notify(queue: DispatchQueue.main) {
                    texturesGroup.leave()
                    
                    geometryCompletionHandler()
                    os_log("geometry loaded %d ms", log: log_scenekit, type: .debug, Int(start.timeIntervalSinceNow * -1000))
                    
                    DispatchQueue.main.async {
                        self._nodesConverted(self.errorMessage)
                    }
                }
                
                convertGroup.leave()
            } else {
                var err:Error?
                do {
                    for nodeIndex in sceneGlTF.nodes! {
                        if let scnNode = try self.buildNode(nodeIndex:nodeIndex) {
                            scnNode.isHidden = hidden
                            scene.rootNode.addChildNode(scnNode)
                        }
                    }
                } catch {
                    err = error
                }
                convertGroup.leave()
                self._nodesConverted(err)
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
        TextureStorageManager.manager.clear(gltf: self);
    }
    
    internal func _constructNodesTree(rootNode:SCNNode, nodes:[Int], group:DispatchGroup, hidden:Bool) {
        var cache_nodes = self.cache_nodes
        for nodeIndex in nodes {
            
            if (self.isCancelled) {
                return
            }
            
            group.enter()                           // <=== enter group
            
            let scnNode = SCNNode()
            scnNode.isHidden = hidden
            if let node = self.nodes?[nodeIndex] {
                scnNode.name = node.name
                
                let haveChilds = node.children != nil && node.children?.count != 0
                if haveChilds {
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
            cache_nodes?[nodeIndex] = scnNode
            
            self._preloadBuffersData(nodeIndex: nodeIndex) { error in
                if error != nil {
                    print("Failed to load geometry node with error: \(error!)")
                    self.errorMessage = error
                    self.cancel()
                } else {
                    do {
                        _ = try self.buildNode(nodeIndex: nodeIndex, scnNode: scnNode)
                    } catch {
                        print(error)
                        self.errorMessage = error
                        self.cancel()
                    }
                }
                group.leave()                      // <=== leave group
            }
        }
    }
    
     
    /// Nodes converted, start parse and create animation. 
    /// And in case no textures required to load, complete convertion from glTF to SceneKit.
    fileprivate func _nodesConverted(_ error:Error?) {
        self.convertionProgressMask.insert(.nodes)
        
        if let e = error {
            self.errorMessage = e
            self.cancel()
            
            // because we cancel, have to mark as pass progress
            self.convertionProgressMask.insert(.textures)
            self.convertionProgressMask.insert(.animations)
        } else {
        
            do {
                try self.parseAnimations()
            } catch {
                self.errorMessage = error
                self.cancel()
            }
            // probably should be inserted some where else and call on completion of animation parse
            self.convertionProgressMask.insert(.animations)
        }
        
        self.nodesDispatchGroup.wait()
        
        if self.textures?.count == 0 {
            self.convertionProgressMask.insert(.textures)
        }
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted(self.errorMessage)
        }
    }
    
    internal func _texturesLoaded() {
        self.convertionProgressMask.insert(.textures)
        TextureStorageManager.manager.clear(gltf: self)
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted(self.errorMessage)
        }
    }
    
    /// Completion function and cache cleaning.
    internal func _converted(_ error:Error?) {
        os_log("convert completed", log: log_scenekit, type: .debug)
        
        loadingDelegate?.scene?(loadingScene)
        loadingDelegate = nil
        loadingScene = SCNScene()
        
        // clear cache
        _completionHandler(error)
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
    
    fileprivate func buildNode(nodeIndex:Int, scnNode:SCNNode = SCNNode()) throws  -> SCNNode? {
        
        if let node = self.nodes?[nodeIndex] {
            
            // Get camera, if it has reference on any. 
            constructCamera(node, scnNode)
            
            // convert meshes if any exists in gltf node
            try geometryNode(node, scnNode)
            
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
                    if let subSCNNode = try self.buildNode(nodeIndex:i) {
                        scnNode.addChildNode(subSCNNode)
                    }
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
                    if #available(OSX 10.13, iOS 11.0, tvOS 11.0, *) {
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
                if let camera = scnNode.camera {
                    loadingDelegate?.scene?(loadingScene, didCreate: camera)
                }
            }
        }
    }  
    
    internal func clearCache() {
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
    
    internal func device() -> MTLDevice? {
        var device:MTLDevice?
        #if os(macOS)
        device = self.renderer?.device
        #endif
        if (device == nil) {
            device = MTLCreateSystemDefaultDevice()
        }
        return device
    }
}
