import XCTest
import SceneKit
@testable import glTFSceneKit

class LoadingDelegate : SceneLoadingDelegate {
    
} 

class gltf_scenekitTests: XCTestCase {
    
    let jsonStringSimple = """
    { "accessors": [ ], "asset": { "copyright": "3D4Medical LLC", "generator": "Comanche", "version": "2.0" }, "bufferViews": [ { "buffer": 0, "byteLength": 118766, "byteStride": 44, "target": 34962 }], "buffers": [ { "byteLength": 118766, "uri": "draco/file.bin" }], "extensionsRequired": [ ], "extensionsUsed": [], "images": [ { "mimeType": "image/png", "uri": "png/texture.png" }, { "mimeType": "image/png", "uri": "png/texture.png" }], "materials": [ { "alphaMode": "OPAQUE", "name": "", "normalTexture": { "index": 1 }, "pbrMetallicRoughness": { "baseColorFactor": [ 0.725279, 0.700000, 0.734000, 1.000000], "baseColorTexture": { "index": 0 }, "metallicFactor": 0.000000, "roughnessFactor": 0.800000 } }], "meshes": [ { "primitives": [ { "attributes": { }, "extensions": { "KHR_draco_mesh_compression" : { "attributes": { "TEXCOORD_0" : 2, "NORMAL" : 1, "TANGENT" : 3, "POSITION" : 0}, "bufferView": 0 }}, "material": 0, "mode": 5 }] }], "nodes": [ { "mesh": 0 }], "samplers": [ { "magFilter": 9729, "minFilter": 9729, "wrapS": 10497, "wrapT": 10497 }], "scene": 0, "scenes": [ { "nodes": [ 0] }], "textures": [ { "sampler": 0, "source": 0 }, { "sampler": 0, "source": 1 }] }
    """
    func testSimpleGLTFinit() {

        let view = SCNView()
        view.scene = SCNScene()

        let jsonData = jsonStringSimple.data(using: .utf8)
        let decoder = JSONDecoder()
        let loadingDelegate = LoadingDelegate()

        if let glTF = try? decoder.decode(GLTF.self, from: jsonData!) {
            let converter = GLTFConverter(glTF: glTF)
            converter.delegate = loadingDelegate 
            let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
                print("Geometry loaded")
            }) { (error) in
                print("Completed with \((error != nil) ? "\(error.debugDescription)" : "no errors")")
            }
            XCTAssert(scene != nil)
        }
    }
    
    // Test where it's failed on extension
    let jsonStringExt = """
    { "accessors": [ ], "asset": { "copyright": "3D4Medical LLC", "generator": "Comanche", "version": "2.0" }, "bufferViews": [ { "buffer": 0, "byteLength": 118766, "byteStride": 44, "target": 34962 }], "buffers": [ { "byteLength": 118766, "uri": "draco/file.bin" }], "extensionsRequired": [ "KHR_draco_mesh_compression"], "extensionsUsed": [ "KHR_draco_mesh_compression"], "images": [ { "mimeType": "image/png", "uri": "png/texture.png" }, { "mimeType": "image/png", "uri": "png/texture.png" }], "materials": [ { "alphaMode": "OPAQUE", "name": "", "normalTexture": { "index": 1 }, "pbrMetallicRoughness": { "baseColorFactor": [ 0.725279, 0.700000, 0.734000, 1.000000], "baseColorTexture": { "index": 0 }, "metallicFactor": 0.000000, "roughnessFactor": 0.800000 } }], "meshes": [ { "primitives": [ { "attributes": { }, "extensions": { "KHR_draco_mesh_compression" : { "attributes": { "TEXCOORD_0" : 2, "NORMAL" : 1, "TANGENT" : 3, "POSITION" : 0}, "bufferView": 0 }}, "material": 0, "mode": 5 }] }], "nodes": [ { "mesh": 0 }], "samplers": [ { "magFilter": 9729, "minFilter": 9729, "wrapS": 10497, "wrapT": 10497 }], "scene": 0, "scenes": [ { "nodes": [ 0] }], "textures": [ { "sampler": 0, "source": 0 }, { "sampler": 0, "source": 1 }] }
    """
    func testGLTFfailure() {

            let view = SCNView()
            view.scene = SCNScene()

            let jsonData = jsonStringExt.data(using: .utf8)
            let decoder = JSONDecoder()
            let loadingDelegate = LoadingDelegate()

            if let glTF = try? decoder.decode(GLTF.self, from: jsonData!) {
                let converter = GLTFConverter(glTF: glTF)
                converter.delegate = loadingDelegate 
                let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
                    print("Geometry loaded")
                }) { (error) in
                    XCTAssert(error != nil)
                    print("Completed with \((error != nil) ? "\(error.debugDescription)" : "no errors")")
                }
                XCTAssert(scene == nil)
            }
        }
}
