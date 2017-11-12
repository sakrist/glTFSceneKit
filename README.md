# GLTF extension for SceneKit


 - [X] Compilable for macOS and iOS
 - [X] Objective-C support
 - [X] Morph animation
 - [ ] Skin and joint animation
 - [ ] Optimise buffer unpacking
 


Example:
```swift
import gltf_scenekit

let directory = "..." // path folder with gltf resources
let decoder = JSONDecoder()
let glTF = try? decoder.decode(GLTF.self, from: jsonData)
let scene:SCNScene = scene = glTF?.convertToSCNScene(directoryPath:directory)
```
