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
    
    
    var infoEntity: ModelEntity? = nil
    var nodeEntity: Entity? = nil
    
    convenience init(pos: SIMD3<Float>, onTapNode: ((ARNode) -> Void)? = nil, onTapInfo: ((ARNode) -> Void)? = nil) {
        self.init()
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
        self.nodeEntity?.name = "VirtualNode1"
        self.addChild(self.nodeEntity!)
        
        self.infoEntity = ModelEntity(
            mesh: .generateText(
                "",
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.1),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            ),
            materials: [SimpleMaterial(color: .white, isMetallic: true)])
        self.infoEntity?.setPosition([0, 0, 0.1], relativeTo: self.nodeEntity!)
        self.infoEntity?.name = "InfoNode1"
        self.addChild(self.infoEntity!)
        
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
            mode: .trigger,
            filter: .sensor
        )
        
        
        //self.generateCollisionShapes(recursive: true)
        
        self.position = pos
        
    }
    
    func updateData(newData: String) {
        self.infoEntity?.model = ModelComponent(
            mesh: .generateText(
                "\(newData)",
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.1),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            ),
            materials: [SimpleMaterial(color: .black, isMetallic: false)]
        )
    }
    
    required init() {
        super.init()
    }
}
