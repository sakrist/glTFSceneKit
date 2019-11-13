//
//  GLTF+Geometry.swift
//  glTFSceneKit
//
//  Created by sergey.novikov on 03/10/2019.
//

import SceneKit


extension GLTFMeshPrimitiveMode {
    public func scn() -> SCNGeometryPrimitiveType {
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

extension GLTFAccessor {
    public func components() -> Int {
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
    
    public func bytesPerElement() -> Int {
        switch componentType {
        case .UNSIGNED_BYTE, .BYTE:
            return 1
        case .UNSIGNED_SHORT, .SHORT:
            return 2
        default:
            return 4
        }
    }
    
    public func vertexFormat() -> MTLVertexFormat {
        switch type {
        case .SCALAR:
            switch componentType {
            case .UNSIGNED_SHORT, .SHORT, .UNSIGNED_BYTE, .BYTE:
                fatalError("Unsupported")
                
            case .UNSIGNED_INT:
                return .uint
            case .FLOAT:
                return .float
            }
            
        case .VEC2:
            switch componentType {
            case .UNSIGNED_SHORT:
                return .ushort2
            case .SHORT:
                return .short2
            case .UNSIGNED_BYTE:
                return .uchar2
            case .BYTE:
                return .char2
            case .UNSIGNED_INT:
                return .uint2
            case .FLOAT:
                return .float2
            }
            
        case .VEC3:
            switch componentType {
            case .UNSIGNED_SHORT:
                return .ushort3
            case .SHORT:
                return .short3
            case .UNSIGNED_BYTE:
                return .uchar3
            case .BYTE:
                return .char3
            case .UNSIGNED_INT:
                return .uint3
            case .FLOAT:
                return .float3
            }
        
        case .VEC4:
            switch componentType {
            case .UNSIGNED_SHORT:
                return .ushort4
            case .SHORT:
                return .short4
            case .UNSIGNED_BYTE:
                return .uchar4
            case .BYTE:
                return .char4
            case .UNSIGNED_INT:
                return .uint4
            case .FLOAT:
                return .float4
            }
            
        default:
            fatalError("Unsupported")
        }
    }
}

fileprivate extension GLTF {
    //let buffer = glTF.buffers![glTF.bufferViews![bufferView].buffer]
    func buffer(for bufferView: Int) -> GLTFBuffer? {
        if let bufferIndex = self.bufferViews?[bufferView].buffer {
            return self.buffers?[bufferIndex]
        }
        
        return nil
    }
}


extension GLTFConverter {
    
    
    /// convert glTF mesh into SCNGeometry
    ///
    /// - Parameters:
    ///   - node: gltf node
    ///   - scnNode: SceneKit node, which is going to be parent node
    internal func geometryNode(_ node:GLTFNode, _ scnNode:SCNNode) throws {
        
        if glTF.isCancelled {
            return
        }
        
        if let meshIndex = node.mesh {
            
            var weightPaths = [String]()
            
            if let mesh = glTF.meshes?[meshIndex] {
                
                var primitiveIndex = 0
                
                for primitive in mesh.primitives {
                    
                    var sources:[SCNGeometrySource] = [SCNGeometrySource]()
                    var elements:[SCNGeometryElement] = [SCNGeometryElement]()
                    
                    // get indices
                    if let element = try self.geometryElement(primitive) {
                        elements.append(element)
                    }
                    
                    // get sources from attributes information
                    if let geometrySources = try self.geometrySources(primitive.attributes) {
                        sources.append(contentsOf: geometrySources)
                    }
                    
                    // check on draco extension
                    if let dracoMesh = primitive.extensions?[dracoExtensionKey] {
                        let (dElement, dSources) = try glTF.convertDracoMesh(dracoMesh as! GLTFKHRDracoMeshCompressionExtension)
                        
                        if (dElement != nil) {
                            elements.append(dElement!)
                        }
                        
                        if (dSources != nil) {
                            sources.append(contentsOf: dSources!)
                        }
                    }
                    
                    if glTF.isCancelled {
                        return
                    }
                    
                    
                    let primitiveNode:SCNNode
                    // create geometry
                    let geometry = SCNGeometry.init(sources: sources, elements: elements)
                    
                    if primitiveIndex < scnNode.childNodes.count  {
                        primitiveNode = scnNode.childNodes[primitiveIndex]
                        primitiveNode.geometry = geometry
                    } else {
                        primitiveNode = SCNNode.init(geometry: geometry)
                        scnNode.addChildNode(primitiveNode)
                    }
                    
                    primitiveNode.name = mesh.name
                    
                    delegate?.scene?(loadingScene!, didCreate: primitiveNode)
                    
                    if primitiveNode.geometry?.firstMaterial != nil {
                        // create empty SCNMaterial. Callbacks call later then materail will be download, so we must provide materail for selection
                        let emptyMaterial = SCNMaterial()
                        emptyMaterial.name = "empty"
                        emptyMaterial.isDoubleSided = true
                        
                        primitiveNode.geometry!.firstMaterial = emptyMaterial
                    }
                
                    if let materialIndex = primitive.material {
                        self.glTF.loadMaterial(index:materialIndex, delegate: self, textureChangedCallback: { _ in
                            if let material = primitiveNode.geometry?.firstMaterial {
                                if let texture = material.diffuse.contents as? MTLTexture {
                                    if texture.pixelFormat.hasAlpha() {
                                        primitiveNode.renderingOrder = 10
                                    }
                                }
                            }
                        }) { [unowned self] scnMaterial in
                            self.delegate?.scene?(self.loadingScene!, didCreate: scnMaterial, for: primitiveNode)

                            let emissionContent = primitiveNode.geometry?.firstMaterial?.emission.contents
                            scnMaterial.emission.contents = emissionContent
                            
                            geometry.materials = [scnMaterial]
                        }
                    }

                    if let transparency = primitiveNode.geometry?.firstMaterial?.transparency,
                        transparency < 1.0 {
                        primitiveNode.renderingOrder = 10
                    }
                    
                    if glTF.isCancelled {
                        return
                    }
                    
                    if let targets = primitive.targets {
                        let morpher = SCNMorpher()
                        let targetsCount = targets.count
                        for targetIndex in 0..<targetsCount {
                            let target = targets[targetIndex]
                            if let sourcesMorph = try geometrySources(target) {
                                let geometryMorph = SCNGeometry(sources: sourcesMorph, elements: nil)
                                morpher.targets.append(geometryMorph)
                                
                                let path = "childNodes[\(primitiveIndex)].morpher.weights[\(targetIndex)]"
                                weightPaths.append(path)
                            }
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
    
    fileprivate func geometryElement(_ primitive: GLTFMeshPrimitive) throws -> SCNGeometryElement? {
        if let indicesIndex = primitive.indices {
            if let accessor = glTF.accessors?[indicesIndex],
                let bufferViewIndex = accessor.bufferView,
                let bufferView = glTF.bufferViews?[bufferViewIndex] {
                
                if let indicesData = try loadAcessor(accessor, bufferView, false) {
                    
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
                }
            } else {
                throw GLTFError("Can't find indices acessor with index \(indicesIndex)")
            }
        }
        return nil
    }
    
    /// Convert mesh/animation attributes into SCNGeometrySource
    ///
    /// - Parameter attributes: dictionary of accessors
    /// - Returns: array of SCNGeometrySource objects
    fileprivate func geometrySources(_ attributes:[String:Int]) throws -> [SCNGeometrySource]?  {
        var geometrySources = [SCNGeometrySource]()
        
        // accessors can point to different buffers. We cache last one.
        var previousBufferView = -1
        var mtlBuffer:MTLBuffer?
        
        var byteOffset = 0
        var byteStride = 0
        
        
        for (key, accessorIndex) in attributes {
            if let accessor = glTF.accessors?[accessorIndex],
                let (bufferView, interleaved) = try determineAcessor(accessor) {
                
                byteOffset = (interleaved) ? accessor.byteOffset : 0
                byteStride = bufferView.byteStride ?? 0
                
                if (mtlBuffer == nil || previousBufferView != accessor.bufferView!) {
                    if let data = try loadAcessor(accessor, bufferView, interleaved) {
                        
                        let device = self.device()
                        data.withUnsafeBytes { (unsafeBufferPointer:UnsafeRawBufferPointer) in
                            let uint8Ptr = unsafeBufferPointer.bindMemory(to: Int8.self).baseAddress!
                            mtlBuffer = device?.makeBuffer(bytes: uint8Ptr, length: data.count, options: .storageModeShared)
                        }
                    }
                    previousBufferView = accessor.bufferView!
                }
                
                let count = accessor.count
                
                let vertexFormat:MTLVertexFormat = accessor.vertexFormat()
                
                // convert string semantic to SceneKit semantic type
                let semantic = GLTF.sourceSemantic(name:key)
                
                if let mtlB = mtlBuffer {
                    let geometrySource = SCNGeometrySource.init(buffer: mtlB,
                                                                vertexFormat: vertexFormat,
                                                                semantic: semantic,
                                                                vertexCount: count,
                                                                dataOffset: byteOffset,
                                                                dataStride: byteStride)
                    geometrySources.append(geometrySource)
                } else {
                    // TODO: implement fallback on init with data, which was deleted
                    
                    throw GLTFError("Metal device failed to allocate MTLBuffer with accessor.bufferView = \(accessor.bufferView!)")
                }
            } else {
                throw GLTFError("Can't locate accessor at \(accessorIndex) index")
            }
        }
        return geometrySources
    }
    

    // TODO: Collect associated buffers for node into a Set on Decode time.
    internal func _preloadBuffersData(nodeIndex:Int, completionHandler: @escaping (Error?) -> Void ) {
        
        var buffers:Set = Set<GLTFBuffer>()
        
        let insertBuffer: ( (Int?)->Void ) = { [weak self] index in
            guard let index = index else {
                return
            }
            
            if let accessor = self?.glTF.accessors?[index] {
                if let bufferView = accessor.bufferView,
                    let buffer = self?.glTF.buffer(for: bufferView) {
                    buffers.insert(buffer)
                } else {
                    self?.errorMessage = GLTFError("Can't locate buffer with accessor at \(index) index")
                }
            }
        }
        
        if let node = glTF.nodes?[nodeIndex],
            let meshIndex = node.mesh,
            let mesh = glTF.meshes?[meshIndex] {
            
            for primitive in mesh.primitives {
                // check on draco extension
                if let dracoMesh = primitive.extensions?[dracoExtensionKey] {
                    if let dracoMesh = dracoMesh as? GLTFKHRDracoMeshCompressionExtension {
                        if let buffer = glTF.buffer(for: dracoMesh.bufferView) {
                            buffers.insert(buffer)
                        } else {
                            errorMessage = GLTFError("Can't locate draco buffer with bufferView at \(dracoMesh.bufferView) index")
                        }
                        
                    } else {
                        errorMessage = GLTFError("Draco extension not compatible for mesh at \(meshIndex) index")
                    }
                    
                } else {
                    primitive.attributes.forEach { (_, index) in
                        insertBuffer(index)
                    }
                    insertBuffer(primitive.indices)
                }
            }
        }
        
        glTF.loader.load(gltf:glTF, resources: buffers, options: ResourceType.buffer, completionHandler:completionHandler)
    }
    
    
    // determine where an accessor and a bufferView link are interleaved or not
    internal func determineAcessor(_ accessor:GLTFAccessor) throws -> (GLTFBufferView, Bool)? {
        
        guard let index =  accessor.bufferView else {
            throw GLTFError("Missing 'bufferView' for \(accessor.name ?? "") acessor")
        }
        
        if let bufferView = glTF.bufferViews?[index] {
            
            // Interleaved data usualy has bytesStride as correct value.
            // Some times non-interleaved data also has bytesStride, and in some cases don't. It's up to exporter
            // We do calculate bytesStride for accessor manualy and compare it later to determine if our data is interleaved or not.
            let byteStride:Int = bufferView.byteStride ?? 0
            let accessorByteStride = accessor.components()*accessor.bytesPerElement()
            
            let interleaved = (byteStride != accessorByteStride)
            return (bufferView, interleaved)
        }
        return nil
    }
    
    
    // get data by accessor
    internal func loadAcessor(_ accessor:GLTFAccessor, _ bufferView:GLTFBufferView, _ interleaved:Bool) throws -> Data? {
        
        if let data = try GLTF.requestData(glTF: glTF, bufferView: bufferView) {
            
            var byteStride:Int = bufferView.byteStride ?? 0
            if (byteStride == 0) {
                byteStride = accessor.components()*accessor.bytesPerElement()
            }
            // calculate length
            let bytesLength = byteStride * accessor.count
            
            // calculate range
            let start = bufferView.byteOffset + ((!interleaved) ? accessor.byteOffset : 0)
            let end = start + bytesLength
            
            var subdata = data
            if start != 0 || end != data.count {
                subdata = data.subdata(in: start..<end)
            }
            
            return subdata
        }
        
        return nil
    }
    
    
   
}
