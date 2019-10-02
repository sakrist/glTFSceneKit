//
//  GLTF+Animation.swift
//  gltf_scenekit
//
//  Created by Volodymyr Boichentsov on 24/04/2018.
//

import Foundation
import SceneKit

extension GLTF {
    
    var animationDuration:Double {
        get { return (objc_getAssociatedObject(self, &Keys.animation_duration) as? Double ?? 0) }        
        set { objc_setAssociatedObject(self, &Keys.animation_duration, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func parseAnimations() throws {
        if self.animations != nil {
            for animation in self.animations! {
                for channel in animation.channels {
                    let sampler = animation.samplers[channel.sampler]
                    try constructAnimation(sampler: sampler, target:channel.target)
                }
            }
        }
        
        for node in self.cache_nodes! {
            let group = node?.value(forUndefinedKey: "group") as? CAAnimationGroup
            if group != nil && self.animationDuration != 0 {
                group?.duration = self.animationDuration
            }
        }
    }
    
    func constructAnimation(sampler:GLTFAnimationSampler, target:GLTFAnimationChannelTarget ) throws {
        
        let targetIndex = target.node!
        guard let node:SCNNode = self.cache_nodes?[targetIndex] else {
            throw "constructAnimation: Can't find target node with \(targetIndex), sampler:\(sampler) target:\(target)"
        }
        
        guard let accessorInput = self.accessors?[sampler.input] else {
            throw "Input accessor could not be found for sampler.input \(sampler.input)"
        }
        guard let accessorOutput = self.accessors?[sampler.output] else {
            throw "Output accessor could not be found for sampler.output \(sampler.output)"
        }
        
        var keyTimesFloat = [Float]()
        if let (data, _, _) = try loadAcessor(accessorInput) {
            keyTimesFloat = dataAsArray(data, accessorInput.componentType, accessorInput.type) as! [Float]
        }
        let duration = Double(keyTimesFloat.last!)
        let f_duration = Float(duration)
        let keyTimes: [NSNumber] = keyTimesFloat.map { NSNumber(value: $0 / f_duration ) }
        
        var values_ = [Any]()
        if let (data, _, _) = try loadAcessor(accessorOutput) {
            values_ = dataAsArray(data, accessorOutput.componentType, accessorOutput.type)
        }
        
        var groupDuration:Double = 0
        
        var caanimations:[CAAnimation] = [CAAnimation]() 
        if target.path == .weights {
            let weightPaths = node.value(forUndefinedKey: "weightPaths") as? [String]
            
            groupDuration = duration
            
            var keyAnimations = [CAKeyframeAnimation]()
            for path in weightPaths! {
                let animation = CAKeyframeAnimation()
                animation.keyPath = path
                animation.keyTimes = keyTimes
                animation.duration = duration
                keyAnimations.append(animation)
            }
            
            let step = keyAnimations.count
            let dataLength = values_.count / step
            guard dataLength == keyTimes.count else {
                throw "data count mismatch: \(dataLength) != \(keyTimes.count)"
            }
            
            for i in 0..<keyAnimations.count {
                var valueIndex = i
                var v = [NSNumber]()
                v.reserveCapacity(dataLength)
                for _ in 0..<dataLength {
                    v.append(NSNumber(value: (values_[valueIndex] as! Float) ))
                    valueIndex += step
                }
                keyAnimations[i].values = v
            }
            
            caanimations = keyAnimations
            
        } else {
            let keyFrameAnimation = CAKeyframeAnimation()
            
            self.animationDuration = max(self.animationDuration, duration)
            
            keyFrameAnimation.keyPath = target.path.scn()
            keyFrameAnimation.keyTimes = keyTimes
            keyFrameAnimation.values = values_
            keyFrameAnimation.repeatCount = .infinity
            keyFrameAnimation.duration = duration
            
            caanimations.append(keyFrameAnimation)
            
            groupDuration = self.animationDuration
        }
        
        let group = (node.value(forUndefinedKey: "group") as? CAAnimationGroup) ?? CAAnimationGroup()
        node.setValue(group, forUndefinedKey: "group")
        var animations = group.animations ?? []
        animations.append(contentsOf: caanimations)
        group.animations = animations 
        group.duration = groupDuration
        group.repeatCount = .infinity
        node.addAnimation(group, forKey: target.path.rawValue)
    }
    
    func loadSkin(_ skin:Int, _ scnNode:SCNNode) {
        // TODO: implement
    }
    
    func dataAsArray(_ data:Data, _ componentType:GLTFAccessorComponentType, _ type:GLTFAccessorType) -> [Any] {
        var values = [Any]()
        switch componentType {
        case .BYTE:
            values = data.array() as [Int8]
            break
        case .UNSIGNED_BYTE:
            values = data.array() as [UInt8]
            break
        case .SHORT:
            values = data.array() as [Int16]
            break
        case .UNSIGNED_SHORT:
            values = data.array() as [UInt16]
            break
        case .UNSIGNED_INT:
            values = data.array() as [UInt32]
            break
        case .FLOAT: 
            do {
                switch type {
                case .SCALAR:
                    values = data.array() as [Float]
                    break
                case .VEC2:
                    values = data.array() as [SCNVector2]
                    break
                case .VEC3:
                    values = data.array() as [GLKVector3]
                    for i in 0..<values.count {
                        values[i] = SCNVector3FromGLKVector3(values[i] as! GLKVector3)
                    }
                    break
                case .VEC4:
                    values = data.array() as [GLKVector4]
                    for i in 0..<values.count {
                        values[i] = SCNVector4FromGLKVector4(values[i] as! GLKVector4)
                    }
                    break
                case .MAT2:
                    break
                case .MAT3:
                    break
                case .MAT4:
                    values = data.array() as [GLKMatrix4]
                    for i in 0..<values.count {
                        values[i] = SCNMatrix4FromGLKMatrix4(values[i] as! GLKMatrix4)
                    }
                    break
                }
            }
            break
        }
        return values
    }
    
}


extension GLTFAnimationChannelTargetPath {
    fileprivate func scn() -> String {
        switch self {
        case .translation:
            return "position"
        case .rotation:
            return "orientation"
        case .scale:
            return self.rawValue
        case .weights:
            return self.rawValue
        }
    }
}


