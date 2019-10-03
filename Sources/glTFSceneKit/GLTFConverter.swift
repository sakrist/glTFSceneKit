//
//  GLTFConverter.swift
//  glTFSceneKit
//
//  Created by sergey.novikov on 03/10/2019.
//

import SceneKit
import os

class GLTFConverter {
    
    /// Status will be true if `cancel` was call.
    @objc open private(set) var isCancelled: Bool = false
    @objc open private(set) var errorMessage: Error?
    
    internal private(set) var cache_nodes: [SCNNode?]?
    
    internal var _completionHandler: ((Error?) -> Void) = { _ in }
    internal var nodesDispatchGroup: DispatchGroup = DispatchGroup()
    internal var convertionProgressMask: ConvertionProgressMask = ConvertionProgressMask(rawValue: 0)
    
    internal var renderer: SCNSceneRenderer?
    internal var loadingScene: SCNScene?
    internal var loadingDelegate:SceneLoadingDelegate?
    
    internal var glTF: GLTF
    
    init(glTF: GLTF) {
        self.glTF = glTF
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
        
        if (glTF.extensionsUsed != nil) {
            //            for key in self.extensionsUsed! {
            //                if !supportedExtensions.contains(key) {
            //                    completionHandler("Used `\(key)` extension is not supported!")
            //                    return nil
            //                }
            //            }
        }
        
        if (glTF.extensionsRequired != nil) {
            for key in glTF.extensionsRequired! {
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
            glTF.loader.directoryPath = directoryPath!
        }
        
        // Get dispatch group for current GLTF
        let convertGroup = self.nodesDispatchGroup
        convertGroup.enter()
        
        if glTF.scenes != nil && glTF.scene != nil {
            let sceneGlTF = glTF.scenes![(glTF.scene)!]
            if let sceneName = sceneGlTF.name {
                scene.setAttribute(sceneName, forKey: "name")
            }
            
            self.cache_nodes = [SCNNode?](repeating: nil, count: glTF.nodes!.count)
            
            // run in multi-thread or single
            if (multiThread) {
                
                let start = Date()
                
                // this enter is requered here in case materials has few textures
                // which loaded very quickly even before all geometries submitted for load
                let texturesGroup = TextureStorageManager.manager.group(gltf: glTF, true)
                
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
        glTF.loader.cancelAll()
        TextureStorageManager.manager.clear(gltf: glTF);
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
            if let node = glTF.nodes?[nodeIndex] {
                scnNode.name = node.name
                
                let haveChilds = node.children != nil && node.children?.count != 0
                if haveChilds {
                    _constructNodesTree(rootNode: scnNode, nodes: node.children!, group: group, hidden: hidden)
                }
                
                // create nodes up front to avoid deadlocks in multithreading
                let primitivesCount = glTF.meshes?[node.mesh!].primitives.count ?? 0
                for _ in 0..<primitivesCount {
                    let scnNodePrimitiveNode = SCNNode()
                    scnNode.addChildNode(scnNodePrimitiveNode)
                }
            }
            rootNode.addChildNode(scnNode)
            cache_nodes?[nodeIndex] = scnNode
            
            glTF._preloadBuffersData(nodeIndex: nodeIndex) { error in
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
                try glTF.parseAnimations()
            } catch {
                self.errorMessage = error
                self.cancel()
            }
            // probably should be inserted some where else and call on completion of animation parse
            self.convertionProgressMask.insert(.animations)
        }
        
        self.nodesDispatchGroup.wait()
        
        if glTF.textures?.count == 0 {
            self.convertionProgressMask.insert(.textures)
        }
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted(self.errorMessage)
        }
    }
    
    internal func _texturesLoaded() {
        self.convertionProgressMask.insert(.textures)
        TextureStorageManager.manager.clear(gltf: glTF)
        
        if self.convertionProgressMask.rawValue == ConvertionProgressMask.all().rawValue {
            self._converted(self.errorMessage)
        }
    }
    
    /// Completion function and cache cleaning.
    internal func _converted(_ error:Error?) {
        os_log("convert completed", log: log_scenekit, type: .debug)
        
        loadingDelegate?.scene?(loadingScene!)
        loadingDelegate = nil
        loadingScene = SCNScene()
        
        // clear cache
        _completionHandler(error)
        _completionHandler = {_ in }
        
        self.cache_nodes?.removeAll()
        
        self.clearCache()
        
    }
    
    // MARK: - Nodes
    
    fileprivate func buildNode(nodeIndex:Int, scnNode:SCNNode = SCNNode()) throws  -> SCNNode? {
        
        if let node = glTF.nodes?[nodeIndex] {
            
            // Get camera, if it has reference on any.
            constructCamera(node, scnNode)
            
            // convert meshes if any exists in gltf node
            try glTF.geometryNode(node, scnNode)
            
            // load skin if any reference exists
            if let skin = node.skin {
                glTF.loadSkin(skin, scnNode)
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
            if glTF.cameras != nil {
                let camera = glTF.cameras![cameraIndex]
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
                    loadingDelegate?.scene?(loadingScene!, didCreate: camera)
                }
            }
        }
    }
    
    internal func clearCache() {
        if glTF.buffers != nil {
            for buffer in glTF.buffers! {
                buffer.data = nil
            }
        }
        
        if glTF.images != nil {
            for image in glTF.images! {
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
