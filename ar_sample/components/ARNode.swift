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

class ARNode: Entity, HasAnchoring, HasCollision {
    var onTapNode: ((ARNode) -> Void)? = nil
    var onTapInfo: ((ARNode) -> Void)? = nil
    var isInfoShown: Bool = false
    
    var nodeEntity: Entity? = nil
    var customInfoEntity: ARInfoNode? = nil
    
    convenience init(onTapNode: ((ARNode) -> Void)? = nil, onTapInfo: ((ARNode) -> Void)? = nil) {
        self.init()
        let uniqueId = UUID().uuidString
        
        self.transform = Transform()
        self.onTapNode = onTapNode
        self.onTapInfo = onTapInfo
        self.name = uniqueId
        
        let loadedModel: ModelEntity
        do {
            loadedModel = try ModelEntity.loadModel(named: "solar_panels_stylized")
            loadedModel.scale = [0.0003, 0.0003, 0.0003]
            loadedModel.components[CollisionComponent] = CollisionComponent(
                shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
                mode: .trigger,
                filter: .sensor
            )
        } catch {
            loadedModel = ModelEntity(
                mesh: .generateBox(size: 0.1),
                materials: [SimpleMaterial(color: .blue, isMetallic: false)]
            )
        }
        
        self.nodeEntity = loadedModel
        self.nodeEntity?.name = "\(uniqueId)_VirtualNode"
        self.addChild(self.nodeEntity!)
        
        self.customInfoEntity = ARInfoNode(parent: self, name: "\(uniqueId)_InfoNode")
        
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
            mode: .trigger,
            filter: .sensor
        )
        self.generateCollisionShapes(recursive: false)
    }
    
    func updateData(newData: [Int: Double]) {
        self.customInfoEntity?.updateViewWithHarvData(data: newData)
        
    }
    
    func toggleInfo() {
        self.isInfoShown = !self.isInfoShown
        if self.isInfoShown {
            self.addChild(self.customInfoEntity!)
            //self.customInfoEntity?.setPosition([0, 0.3, 0], relativeTo: self.nodeEntity)
            self.customInfoEntity?.position = [0, 0.3, 0]
        } else {
            self.customInfoEntity?.removeFromParent()
        }
    }
    
    required init() {
        super.init()
    }
}

class ARInfoNode: Entity, HasAnchoring, HasModel, HasCollision {
    var lastInfoView: ARNodeInformationSwiftUIView? = nil
    var parentNode: ARNode? = nil
    
    convenience init(parent: ARNode, name: String) {
        self.init()
        self.parentNode = parent
        self.transform = parent.transform
        do {
            var customViewMaterial = SimpleMaterial()
            lastInfoView = ARNodeInformationSwiftUIView(harvData: [:], name: name, battery: 0.75)
            customViewMaterial.baseColor = try MaterialColorParameter.texture(
                .generate(
                    from: lastInfoView!.snapshot(size: CGSize(width: 300, height: 280))!,
                    options: TextureResource.CreateOptions(
                        semantic: nil,
                        mipmapsMode: .allocateAndGenerateAll
                    )
                ))
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.3, 0.28, 0.001]),
                materials: [customViewMaterial]
            )
            self.components[CollisionComponent] = CollisionComponent(
                shapes: [.generateBox(size: [0.3, 0.28, 0.001])],
                mode: .trigger,
                filter: .sensor
            )
            self.name = name
            self.position = [0, 0.4, 0]
        } catch {
            fatalError()
        }
    }
    
    func updateViewWithHarvData(data: [Int: Double]) {
        do {
            var customViewMaterial = SimpleMaterial()
            lastInfoView = ARNodeInformationSwiftUIView(harvData: data, name: lastInfoView!.name, battery: lastInfoView!.battery - 0.001)
            let snapShot = lastInfoView!.uiImage()!
            customViewMaterial.baseColor = try MaterialColorParameter.texture(
                .generate(
                    from: snapShot,
                    options: TextureResource.CreateOptions(
                        semantic: nil,
                        mipmapsMode: .allocateAndGenerateAll
                    )
                ))
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.3, 0.28, 0.001]),
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
