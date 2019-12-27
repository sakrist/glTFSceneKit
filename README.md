# GLTF extension for SceneKit

#### General
 - [X] Compilable for macOS and iOS
 - [X] Objective-C support
 - [X] swift package
 - [ ] GLTF swift extension with wrapper for JSONDecoder
 - [ ] Tests
 - [ ] Convert SceneKit to GLTF
 
 
#### Encodings
 - [X] JSON
 - [ ] Binary (.glb)
 
 
#### Primitive Types
 - [ ] Points
 - [x] Lines
 - [ ] Line Loop
 - [ ] Line Strip
 - [x] Triangles
 - [x] Triangle Strip
 - [ ] Triangle Fan


#### Animation
- [X] Transform animations
- [X] Linear interpolation
- [X] Morph animation
- [ ] Skin and joint animation


#### Extensions 
 - [ ] KHR_draco_mesh_compression - Draco (supported draft version, need rework. temporary disabled)
 - [X] 3D4M_compressed_texture - [Draft of unofficial extension.](https://github.com/sakrist/glTF/tree/extensions/compressed_texture/extensions/2.0/Vendor/3D4M_compressed_texture)  
 

Example:
```swift
import glTFSceneKit

let directory = "..." // path to folder where is gltf file located
let decoder = JSONDecoder()
let glTF = try? decoder.decode(GLTF.self, from: jsonData)
if let converter = GLTFConverter(glTF: glTF) {
    let scene = converter.convert(to: view.scene!, geometryCompletionHandler: { 
    // Geometries are loaded and textures are may still in loading process.
    }) { (error) in
       // Fully converted to SceneKit
       // TODO: handle error.
    }
}
```
