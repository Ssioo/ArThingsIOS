//
//  ARNode.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/05.
//

import Foundation
import RealityKit
import SwiftUI
import ARKit

class ARNode: Entity, HasAnchoring {
    var onTapNode: ((ARNode) -> Void)? = nil
    var onTapInfo: ((ARNode) -> Void)? = nil
    var isInfoShown: Bool = false
    
    var nodeEntity: Entity? = nil
    var customInfoEntity: ARInfoNode? = nil
    
    convenience init(pos: SIMD3<Float>, onTapNode: ((ARNode) -> Void)? = nil, onTapInfo: ((ARNode) -> Void)? = nil) {
        self.init()
        let uniqueId = UUID().uuidString
        
        self.transform = Transform()
        self.onTapNode = onTapNode
        self.onTapInfo = onTapInfo
        let loadedModel: Entity
        do {
            
            loadedModel = try Entity.load(named: "solar_panels_stylized")
            loadedModel.scale = [0.0003, 0.0003, 0.0003]
            debugPrint(loadedModel)
        } catch {
            loadedModel = ModelEntity(
                mesh: .generateBox(size: 0.1),
                materials: [SimpleMaterial(color: .blue, isMetallic: false)]
            )
        }
        
        self.nodeEntity = loadedModel
        self.nodeEntity?.name = "\(uniqueId)_VirtualNode"
        self.addChild(self.nodeEntity!)
        
        
        self.customInfoEntity = ARInfoNode(name: "\(uniqueId)_InfoNode")
        self.customInfoEntity?.setPosition([0, 0.1, 0], relativeTo: self)
        //self.addChild(self.customInfoEntity!)
        
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
            mode: .trigger,
            filter: .sensor
        )
        
        
        //self.generateCollisionShapes(recursive: true)
        self.name = uniqueId
        self.position = pos
        
    }
    
    func updateData(newData: [Int: Double]) {
        
        
    }
    
    func toggleInfo() {
        self.isInfoShown = !self.isInfoShown
        if self.isInfoShown {
            self.addChild(self.customInfoEntity!)
        } else {
            self.removeChild(self.customInfoEntity!)
        }
    }
    
    required init() {
        super.init()
    }
}

class ARInfoNode: Entity, HasAnchoring, HasModel {
    convenience init(name: String) {
        self.init()
        do {
            var customViewMaterial = SimpleMaterial()
            let infoView = ARNodeInfomationView()
            customViewMaterial.baseColor = try MaterialColorParameter.texture(
                .generate(
                    from: infoView.snapshot()!,
                    options: TextureResource.CreateOptions(
                        semantic: nil,
                        mipmapsMode: .allocateAndGenerateAll
                    )
                ))
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.3, 0.1, 0.001]),
                materials: [customViewMaterial]
            )
            self.name = name
        } catch {
            fatalError()
        }
    }
    
    required init() {
        super.init()
    }
}
