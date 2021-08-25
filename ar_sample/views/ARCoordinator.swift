//
//  ARContainer.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//


import RealityKit
import ARKit
import SwiftUI
import Combine
import QuickLook

class ARCoordinator: NSObject {
    var container: ARViewContainer
    var centerPoint: CGPoint? = nil
    //var centerPointLeft10: CGPoint? = nil
    //var centerPointBottom10: CGPoint? = nil
    
    init(_ container: ARViewContainer) {
        self.container = container
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: container.arView), true else {
            return
        }
        
        let tappedObj = container.arView.entity(at: touchInView)
        if tappedObj is ARInfoNode {
            debugPrint("Click ARInfoNode!")
            let parent = (tappedObj as! ARInfoNode).parentNode!
            parent.onTapInfo?(parent)
        } else if tappedObj is ARNode {
            debugPrint("Click ARNode!")
            (tappedObj as! ARNode).onTapNode?(tappedObj as! ARNode)
        } else if tappedObj is ARButton {
            (tappedObj as! ARButton).onTap?(tappedObj as! ARButton)
        } else {
            // Add New Node
            let raycastResult = container.arView.raycast(from: touchInView, allowing: .existingPlaneGeometry, alignment: .any)
            
            guard let firstRayCast = raycastResult.first else { return }
            let pos = firstRayCast.worldTransform.position
            
            container.addButton(pos: pos, text: "ADD Node")
        }
    }
    
    var isMoving = false
    var tempARNode: ARNode? = nil
    var lock = false
    
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer? = nil) {
        if lock { return }
        lock = true
        if sender?.state == UIGestureRecognizer.State.began || sender?.state == UIGestureRecognizer.State.changed {

            // Create Virtual Node in center of the view
            if !self.isMoving {
                let raycastResult = container.arView.raycast(
                    from: centerPoint!,
                    allowing: .existingPlaneGeometry,
                    alignment: .any
                )
                
                guard let firstRayCast = raycastResult.first else { return }
                let pos = firstRayCast.worldTransform.position
                self.isMoving = true
                tempARNode = ARNode(pos: pos, onTapNode: nil, onTapInfo: nil)
                self.container.arView.scene.addAnchor(tempARNode!)
                tempARNode?.setPosition(pos, relativeTo: nil)
            }
        } else if (
            sender?.state == UIGestureRecognizer.State.ended
            || sender?.state == UIGestureRecognizer.State.cancelled
            || sender?.state == UIGestureRecognizer.State.failed
        ) {
            self.isMoving = false
            tempARNode?.removeFromParent()
            tempARNode = nil
        }
        lock = false
    }
}

extension ARCoordinator: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Set CenterPoint
        if self.centerPoint == nil {
            let containerFrame = container.arView.frame
            if !containerFrame.isEmpty {
                self.centerPoint = CGPoint(x: containerFrame.width * 0.5, y: containerFrame.height * 0.5)
                //self.centerPointLeft10 = CGPoint(x: containerFrame.width * 0.5 - 10, y: containerFrame.height * 0.5)
                //self.centerPointBottom10 = CGPoint(x: containerFrame.width * 0.5, y: containerFrame.height * 0.5 + 10)
            }
            return
        }
        let cameraPos = self.container.arView.cameraTransform.translation
        
        // Button Look me
        self.container.vm.previousArButton?.lookatMe(cameraPos)
        
        // Node Info Look me
        self.container.vm.anchors.forEach { arNode, pos in
            let infoEntity = arNode.customInfoEntity
            if infoEntity != nil {
                infoEntity!.setPosition([0, 0.1, 0], relativeTo: infoEntity!.parentNode)
                infoEntity!.lookatMe(cameraPos)
            }
        }
        
        // Moving Temp Node Look me
        if self.tempARNode != nil {
            let centerRaycaseResult = container.arView.raycast(
                from: centerPoint!,
                allowing: .existingPlaneGeometry,
                alignment: .any
            )
//            let centerLeft10RaycaseResult = container.arView.raycast(
//                from: centerPointLeft10!,
//                allowing: .existingPlaneGeometry,
//                alignment: .any
//            )
//            let centerBottom10RaycaseResult = container.arView.raycast(
//                from: centerPointBottom10!,
//                allowing: .existingPlaneGeometry,
//                alignment: .any
//            )
            guard let firstCenterRayCastResult = centerRaycaseResult.first else { return }
//            guard let firstCenterLeft10RayCastResult = centerLeft10RaycaseResult.first else { return }
//            guard let firstCenterBottom10RayCastResult = centerBottom10RaycaseResult.first else { return }
//            let estimatedNormalVector = cross(
//                firstCenterRayCastResult.worldTransform.position - firstCenterLeft10RayCastResult.worldTransform.position,
//                firstCenterRayCastResult.worldTransform.position - firstCenterBottom10RayCastResult.worldTransform.position
//            )

            self.tempARNode!.setPosition(firstCenterRayCastResult.worldTransform.position, relativeTo: nil)
            self.tempARNode!.lookatMe(cameraPos, up: [0, 1, 0])
            //self.tempARNode?.setOrientation(.init(angle: Float.pi / 4.0 , axis: firstCenterRayCastResult.worldTransform.position), relativeTo: nil)
        }
        
        //guard let centerObj = container.arView.entity(at: centerPoint!) as? ARNode else { return }
        
    }
    
    
}

extension String {
    func saveToFile(fileName: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = dir.appendingPathComponent(fileName)
    
        do {
            try self.write(to: filePath, atomically: true, encoding: .utf8)
            return filePath
        } catch let e {
            throw e
        }
    }
}
