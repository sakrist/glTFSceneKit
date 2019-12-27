import XCTest
import SceneKit
@testable import glTFSceneKit

class LoadingDelegate : SceneLoadingDelegate {
    
} 

class gltf_scenekitTests: XCTestCase {
    
    let view = SCNView()
    let scene = SCNScene()
    let loadingDelegate = LoadingDelegate()
    let decoder = JSONDecoder()
    
    override func setUp() {
        view.scene = scene
    }
    
    let jsonStringSimple = """
    { "accessors": [ ], "asset": { "copyright": "3D4Medical LLC", "generator": "Comanche", "version": "2.0" }, "bufferViews": [ { "buffer": 0, "byteLength": 118766, "byteStride": 44, "target": 34962 }], "buffers": [ { "byteLength": 118766, "uri": "draco/file.bin" }], "extensionsRequired": [ ], "extensionsUsed": [], "images": [ { "mimeType": "image/png", "uri": "png/texture.png" }, { "mimeType": "image/png", "uri": "png/texture.png" }], "materials": [ { "alphaMode": "OPAQUE", "name": "", "normalTexture": { "index": 1 }, "pbrMetallicRoughness": { "baseColorFactor": [ 0.725279, 0.700000, 0.734000, 1.000000], "baseColorTexture": { "index": 0 }, "metallicFactor": 0.000000, "roughnessFactor": 0.800000 } }], "meshes": [ { "primitives": [ { "attributes": { }, "extensions": { "KHR_draco_mesh_compression" : { "attributes": { "TEXCOORD_0" : 2, "NORMAL" : 1, "TANGENT" : 3, "POSITION" : 0}, "bufferView": 0 }}, "material": 0, "mode": 5 }] }], "nodes": [ { "mesh": 0 }], "samplers": [ { "magFilter": 9729, "minFilter": 9729, "wrapS": 10497, "wrapT": 10497 }], "scene": 0, "scenes": [ { "nodes": [ 0] }], "textures": [ { "sampler": 0, "source": 0 }, { "sampler": 0, "source": 1 }] }
    """
    func testSimpleGLTFinit() {

        let jsonData = jsonStringSimple.data(using: .utf8)

        let expectationGeometry = self.expectation(description: "Geometry")
        let expectationCompleted = self.expectation(description: "Completed")
        
        if let glTF = try? decoder.decode(GLTF.self, from: jsonData!) {
            let converter = GLTFConverter(glTF: glTF)
            converter.delegate = loadingDelegate 
            let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
                print("Geometry loaded")
                expectationGeometry.fulfill()
            }) { (error) in
                print("Completed with \((error != nil) ? "\(error.debugDescription)" : "no errors")")
                expectationCompleted.fulfill()
            }
            
            waitForExpectations(timeout: 5, handler: nil)
            
            XCTAssert(scene != nil)
        }
    }
    
    // Test where it's failed on extension
    let jsonStringExt = """
    { "accessors": [ ], "asset": { "copyright": "3D4Medical LLC", "generator": "Comanche", "version": "2.0" }, "bufferViews": [ { "buffer": 0, "byteLength": 118766, "byteStride": 44, "target": 34962 }], "buffers": [ { "byteLength": 118766, "uri": "draco/file.bin" }], "extensionsRequired": [ "KHR_draco_mesh_compression"], "extensionsUsed": [ "KHR_draco_mesh_compression"], "images": [ { "mimeType": "image/png", "uri": "png/texture.png" }, { "mimeType": "image/png", "uri": "png/texture.png" }], "materials": [ { "alphaMode": "OPAQUE", "name": "", "normalTexture": { "index": 1 }, "pbrMetallicRoughness": { "baseColorFactor": [ 0.725279, 0.700000, 0.734000, 1.000000], "baseColorTexture": { "index": 0 }, "metallicFactor": 0.000000, "roughnessFactor": 0.800000 } }], "meshes": [ { "primitives": [ { "attributes": { }, "extensions": { "KHR_draco_mesh_compression" : { "attributes": { "TEXCOORD_0" : 2, "NORMAL" : 1, "TANGENT" : 3, "POSITION" : 0}, "bufferView": 0 }}, "material": 0, "mode": 5 }] }], "nodes": [ { "mesh": 0 }], "samplers": [ { "magFilter": 9729, "minFilter": 9729, "wrapS": 10497, "wrapT": 10497 }], "scene": 0, "scenes": [ { "nodes": [ 0] }], "textures": [ { "sampler": 0, "source": 0 }, { "sampler": 0, "source": 1 }] }
    """
    func testGLTFfailure() {

        let expectationGeometry = self.expectation(description: "Geometry")
        let expectationCompleted = self.expectation(description: "Completed")
        
        let jsonData = jsonStringExt.data(using: .utf8)

        if let glTF = try? decoder.decode(GLTF.self, from: jsonData!) {
            let converter = GLTFConverter(glTF: glTF)
            converter.delegate = loadingDelegate 
            let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
                print("Geometry loaded")
                expectationGeometry.fulfill()
            }) { (error) in
                print("Completed with \((error != nil) ? "\(error.debugDescription)" : "no errors")")
                XCTAssert(error != nil) // expecting error here
                expectationGeometry.fulfill()
                expectationCompleted.fulfill()
            }
            waitForExpectations(timeout: 5, handler: nil)
            // expecting no scene here
            XCTAssert(scene == nil)
        }
    }
    
    let box_gltf = """
{"asset":{"generator":"COLLADA2GLTF","version":"2.0"},"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"children":[1],"matrix":[1,0,0,0,0,0,-1,0,0,1,0,0,0,0,0,1]},{"mesh":0}],"meshes":[{"primitives":[{"attributes":{"NORMAL":1,"POSITION":2},"indices":0,"mode":4,"material":0}],"name":"Mesh"}],"accessors":[{"bufferView":0,"byteOffset":0,"componentType":5123,"count":36,"max":[23],"min":[0],"type":"SCALAR"},{"bufferView":1,"byteOffset":0,"componentType":5126,"count":24,"max":[1,1,1],"min":[-1,-1,-1],"type":"VEC3"},{"bufferView":1,"byteOffset":288,"componentType":5126,"count":24,"max":[0.5,0.5,0.5],"min":[-0.5,-0.5,-0.5],"type":"VEC3"}],"materials":[{"pbrMetallicRoughness":{"baseColorFactor":[0.800000011920929,0,0,1],"metallicFactor":0},"name":"Red"}],"bufferViews":[{"buffer":0,"byteOffset":576,"byteLength":72,"target":34963},{"buffer":0,"byteOffset":0,"byteLength":576,"byteStride":12,"target":34962}],"buffers":[{"byteLength":648,"uri":"data:application/octet-stream;base64,AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAAAAAAIA/AAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAAAAAAAAgL8AAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAACAPwAAAAAAAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAAAAAAAAgD8AAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAACAvwAAAAAAAAAAAAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAAAAAAAAAAIC/AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAvwAAAL8AAAA/AAAAPwAAAL8AAAC/AAAAvwAAAL8AAAC/AAAAPwAAAD8AAAA/AAAAPwAAAL8AAAA/AAAAPwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAvwAAAD8AAAA/AAAAPwAAAD8AAAA/AAAAvwAAAD8AAAC/AAAAPwAAAD8AAAC/AAAAvwAAAL8AAAA/AAAAvwAAAD8AAAA/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAvwAAAL8AAAC/AAAAvwAAAD8AAAC/AAAAPwAAAL8AAAC/AAAAPwAAAD8AAAC/AAABAAIAAwACAAEABAAFAAYABwAGAAUACAAJAAoACwAKAAkADAANAA4ADwAOAA0AEAARABIAEwASABEAFAAVABYAFwAWABUA"}]}
"""
    func testGLTFBox() {

        let expectationGeometry = self.expectation(description: "Geometry")
        let expectationCompleted = self.expectation(description: "Completed")
        
        let jsonData = box_gltf.data(using: .utf8)

        if let glTF = try? decoder.decode(GLTF.self, from: jsonData!) {
            let converter = GLTFConverter(glTF: glTF)
            converter.delegate = loadingDelegate 
            let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
                print("Geometry loaded")
                expectationGeometry.fulfill()
            }) { (error) in
                print("Completed with \((error != nil) ? "\(error.debugDescription)" : "no errors")")
                XCTAssert(error == nil)
                expectationCompleted.fulfill()
            }
            
            waitForExpectations(timeout: 5, handler: nil)
            
            XCTAssert(scene != nil)
            let node = scene?.rootNode.childNodes.first?.childNodes.first?.childNodes.first!
            let geometry = node?.geometry
            
            XCTAssert(geometry != nil)
            
            // expecting 24 elements
            XCTAssert(geometry!.sources.first!.vectorCount == 24)
        }
    }
}
