//
//  GLTF+Geometry.swift
//  glTFSceneKit
//
//  Created by sergey.novikov on 03/10/2019.
//

import SceneKit


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
    
    fileprivate func vertexFormat() -> MTLVertexFormat {
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
            
        default:
            fatalError("Unsupported")
        }
    }
}

fileprivate extension GLTF {
    //let buffer = glTF.buffers![glTF.bufferViews![bufferView].buffer]
    func buffer(for bufferView: Int) -> GLTFBuffer {
        return self.buffers![self.bufferViews![bufferView].buffer]
    }
}


extension GLTFConverter {
    
    
    /// convert glTF mesh into SCNGeometry
    ///
    /// - Parameters:
    ///   - node: gltf node
    ///   - scnNode: SceneKit node, which is going to be parent node
    internal func geometryNode(_ node:GLTFNode, _ scnNode:SCNNode) throws {
        
        if self.isCancelled {
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
                    
                    if self.isCancelled {
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
                    
                    loadingDelegate?.scene?(loadingScene!, didCreate: primitiveNode)
                    
                    if primitiveNode.geometry?.firstMaterial != nil {
                        // create empty SCNMaterial. Callbacks call later then materail will be download, so we must provide materail for selection
                        let emptyMaterial = SCNMaterial()
                        emptyMaterial.name = "empty"
                        emptyMaterial.isDoubleSided = true
                        
                        primitiveNode.geometry!.firstMaterial = emptyMaterial
                    }
                    
                    
                    if let materialIndex = primitive.material {
                        glTF.loadMaterial(index:materialIndex, delegate: self, textureChangedCallback: { _ in
                            if let material = primitiveNode.geometry?.firstMaterial {
                                if let texture = material.diffuse.contents as? MTLTexture {
                                    if texture.pixelFormat.hasAlpha() {
                                        primitiveNode.renderingOrder = 10
                                    }
                                }
                            }
                            
                        }) { [unowned self] scnMaterial in
                            self.loadingDelegate?.scene?(self.loadingScene!, didCreate: scnMaterial, for: primitiveNode)
                            
                            let emissionContent = primitiveNode.geometry?.firstMaterial?.emission.contents
                            scnMaterial.emission.contents = emissionContent
                            geometry.materials = [scnMaterial]
                        }
                    }
                    
                    
                    
                    if let transparency = primitiveNode.geometry?.firstMaterial?.transparency,
                        transparency < 1.0 {
                        primitiveNode.renderingOrder = 10
                    }
                    
                    if self.isCancelled {
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
            if let accessor = glTF.accessors?[indicesIndex] {
                
                if let (indicesData, _, _) = try loadAcessor(accessor) {
                    
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
        
        var prevBufferView = -1
        var mtlBuffer:MTLBuffer?
        
        var byteOffset = 0
        var byteStride = 0
        
        
        for (key, accessorIndex) in attributes {
            if let accessor = glTF.accessors?[accessorIndex] {
                
                byteOffset = accessor.byteOffset
                
                if (mtlBuffer == nil || prevBufferView != accessor.bufferView!) {
                    if let (data, _byteStride, _) = try loadAcessor(accessor) {
                        
                        let device = self.device()
                        data.withUnsafeBytes { (unsafeBufferPointer:UnsafeRawBufferPointer) in
                            let uint8Ptr = unsafeBufferPointer.bindMemory(to: Int8.self).baseAddress!
                            mtlBuffer = device?.makeBuffer(bytes: uint8Ptr, length: data.count, options: .storageModeShared)
                        }
                        
                        byteStride = _byteStride
                    }
                    prevBufferView = accessor.bufferView!
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
        
        let insertBuffer: ( (Int?)->Void ) = { index in
            guard let index = index else {
                return
            }
            
            if let accessor = self.glTF.accessors?[index] {
                if let bufferView = accessor.bufferView {
                    buffers.insert(self.glTF.buffer(for: bufferView))
                }
            }
        }
        
        if let node = glTF.nodes?[nodeIndex],
            let meshIndex = node.mesh,
            let mesh = glTF.meshes?[meshIndex] {
            
            for primitive in mesh.primitives {
                // check on draco extension
                if let dracoMesh = primitive.extensions?[dracoExtensionKey] {
                    let dracoMesh = dracoMesh as! GLTFKHRDracoMeshCompressionExtension
                    buffers.insert(glTF.buffer(for: dracoMesh.bufferView))
                } else {
                    primitive.attributes.forEach { (_, index) in
                        insertBuffer(index)
                    }
                    insertBuffer(primitive.indices)
                }
            }
        }
        
        glTF.loader.load(gltf:glTF, resources: buffers, completionHandler:completionHandler)
    }
    
    
    // get data by accessor
    internal func loadAcessor(_ accessor:GLTFAccessor) throws -> (Data, Int, Int)? {
        
        if accessor.bufferView == nil {
            throw GLTFError("Missing 'bufferView' for \(accessor.name ?? "") acessor")
        }
        
        if let (bufferView, data) = try GLTF.requestData(glTF: glTF, bufferView: accessor.bufferView!) {
            
            var addAccessorOffset = false
            if (bufferView.byteStride == nil || accessor.components()*accessor.bytesPerElement() == bufferView.byteStride) {
                addAccessorOffset = true
            }
            
            let count = accessor.count
            let byteStride = (bufferView.byteStride == nil || bufferView.byteStride == 0) ? accessor.components()*accessor.bytesPerElement() : bufferView.byteStride!
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
    
    
   
}
