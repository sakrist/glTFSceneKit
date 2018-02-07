# GLTF extension for SceneKit


 - [X] Compilable for macOS and iOS
 - [X] Objective-C support
 - [X] swift package
 - [X] Morph animation
 - [ ] Skin and joint animation
 - [ ] Optimise buffer unpacking
 - [ ] Support \*.glb
 - [ ] GLTF swift extension with wrapper for JSONDecoder
 - [ ] Tests
 


Example:
```swift
import gltf_scenekit

let directory = "..." // path folder with gltf resources
let decoder = JSONDecoder()
let glTF = try? decoder.decode(GLTF.self, from: jsonData)
let scene:SCNScene = scene = glTF?.convertToSCNScene(directoryPath:directory)
```
