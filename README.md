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
 - [X] KHR_draco_mesh_compression - Draco (supported draft version, need to fix when indices is short)
 - [X] 3D4M_compressed_texture - [Draft of unofficial extension.](https://github.com/sakrist/glTF/tree/extensions/compressed_texture/extensions/2.0/Vendor/3D4M_compressed_texture)  
 
## Dependecies
 
  - [DracoSwiftPackage](https://github.com/3D4Medical/DracoSwiftPackage) - custom Draco package for decode   


Example:
```swift
import gltf_scenekit

let directory = "..." // path folder with gltf resources
let decoder = JSONDecoder()
let glTF = try? decoder.decode(GLTF.self, from: jsonData)
let scene:SCNScene = scene = glTF?.convertToSCNScene(directoryPath:directory)
```
