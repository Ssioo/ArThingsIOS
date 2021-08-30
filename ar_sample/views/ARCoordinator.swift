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
    
    var hasCapturedARNode = false
    var capturedARNode: ARNode? = nil
    var lock = false
    var isUpdatingHarvDataOfCapturedARNode = false
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer? = nil) {
        if self.lock { return }
        self.lock = true
        if sender?.state == UIGestureRecognizer.State.began || sender?.state == UIGestureRecognizer.State.changed {

            // Create Virtual Node in center of the view
            if !self.hasCapturedARNode {
                guard let arNode = container.arView.entity(at: centerPoint!) as? ARNode else {
                    container.vm.alertObject = AlertObject(
                        title: "No ARNode Here",
                        message: "There is no ARNode to select in here. Try Again", onOk: {
                            self.lock = false
                        },
                        onNo: nil)
                    
                    container.vm.isShowAlert = true
                    return
                    
                }
                let raycastResult = container.arView.raycast(
                    from: centerPoint!,
                    allowing: .existingPlaneGeometry,
                    alignment: .any
                )
                guard let firstRayCast = raycastResult.first else {
                    self.lock = false
                    return
                }
                self.hasCapturedARNode = true
                self.capturedARNode = arNode
            }
        } else if (
            sender?.state == UIGestureRecognizer.State.ended
            || sender?.state == UIGestureRecognizer.State.cancelled
            || sender?.state == UIGestureRecognizer.State.failed
        ) {
            self.hasCapturedARNode = false
            if self.capturedARNode != nil {
                let lastPos = container.vm.anchors[self.capturedARNode!]
                container.vm.anchors[self.capturedARNode!] = self.capturedARNode!.position(relativeTo: nil)
                container.vm.updateAnchorsToRemote(
                    currentRoomPath: container.vm.currentRoom,
                    onFail: {
                        self.container.vm.alertObject = AlertObject(
                            title: "Update Fail",
                            message: "Failed to update node's new location",
                            onOk: {
                                self.container.vm.anchors[self.capturedARNode!] = lastPos
                                self.capturedARNode = nil
                            },
                            onNo: nil
                        )
                        self.container.vm.isShowAlert = true
                    },
                    onSuccess: {
                        self.container.vm.alertObject = AlertObject(
                            title: "Update Success",
                            message: "Success to update node's new location",
                            onOk: {
                                self.capturedARNode = nil
                            },
                            onNo: nil
                        )
                        self.container.vm.isShowAlert = true
                    })
            }
        }
        self.lock = false
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
        
        if self.hasCapturedARNode {
            // Center Pos Raycast
            let centerPointRaycastResult = container.arView.raycast(
                from: centerPoint!,
                allowing: .estimatedPlane,
                alignment: .any)
            guard let firstCenterPointRaycastResult = centerPointRaycastResult.first else { return }
            self.capturedARNode?.setPosition(firstCenterPointRaycastResult.worldTransform.position, relativeTo: nil)
            if !self.isUpdatingHarvDataOfCapturedARNode {
                self.isUpdatingHarvDataOfCapturedARNode = true
                container.vm.getSolacleHarvDataAt(
                    pos: firstCenterPointRaycastResult.worldTransform.position,
                    onPogress: nil,
                    onRes: {
                        self.capturedARNode?.updateData(newData: $0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isUpdatingHarvDataOfCapturedARNode = false
                        }
                    }
                )
            }
        
        }
        
        // Center는 커지게
        self.container.vm.anchors.forEach { anchor, pos in
            anchor.focus(false)
        }
        guard let centerObj = self.container.arView.entity(at: centerPoint!) as? ARNode else {
            return
        }
        centerObj.focus(true)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        let planeAnchors = anchors.filter {
            $0 is ARPlaneAnchor
        } as! [ARPlaneAnchor]
        planeAnchors.forEach { anchor in
            
            switch (anchor.classification) {
            case .window:
                debugPrint("\(anchor.identifier) \(anchor.center) window")
                break
            case .wall:
                debugPrint("\(anchor.identifier) \(anchor.center) wall")
                break
            case .none(_):
                break
            case .floor:
                debugPrint("\(anchor.identifier) \(anchor.center) floor")
                break
            case .ceiling:
                debugPrint("\(anchor.identifier) \(anchor.center) ceiling")
                break
            case .table:
                debugPrint("\(anchor.identifier) \(anchor.center) table")
                break
            case .seat:
                debugPrint("\(anchor.identifier) \(anchor.center) seat")
                break
            case .door:
                debugPrint("\(anchor.identifier) \(anchor.center) door")
                break
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let planeAnchors = anchors.filter {
            $0 is ARPlaneAnchor
        } as! [ARPlaneAnchor]
        planeAnchors.forEach { anchor in
            
            switch (anchor.classification) {
            case .window:
                // Add Window Node
                break
            case .wall:
                debugPrint("\(anchor.identifier) \(anchor.center) wall")
                break
            case .none(_):
                break
            case .floor:
                debugPrint("\(anchor.identifier) \(anchor.center) floor")
                break
            case .ceiling:
                debugPrint("\(anchor.identifier) \(anchor.center) ceiling")
                break
            case .table:
                debugPrint("\(anchor.identifier) \(anchor.center) table")
                break
            case .seat:
                debugPrint("\(anchor.identifier) \(anchor.center) seat")
                break
            case .door:
                // Add Door Node
                break
            @unknown default:
                break
            }
        }
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
