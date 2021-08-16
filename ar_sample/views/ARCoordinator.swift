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
            let parent = (tappedObj as! ARInfoNode).parent as! ARNode
            parent.onTapInfo?(parent)
        } else if tappedObj is ARNode {
            debugPrint("Click ARNode!")
            (tappedObj as! ARNode).onTapNode?(tappedObj as! ARNode)
        } else {
            // Add New Node
            let hitTestResult = container.arView.hitTest(touchInView, types: .existingPlane)
            guard let firstHitWTC = hitTestResult.first else { return }
            let x = firstHitWTC.worldTransform.columns.3.x
            let y  = firstHitWTC.worldTransform.columns.3.y
            let z = firstHitWTC.worldTransform.columns.3.z

            container.vm.alertObject = AlertObject(
                title: "Add Node",
                message: "Do you want to place virtual node here?",
                onOk: {
                    self.container.addElement(pos: [x, y, z])
                },
                onNo: {}
            )
            container.vm.isShowAlert = true
        }
        
//        guard let buttonTapped = container.arView.entity(at: touchInView) as? ARNode else {
//            // Add New Node
//            let hitTestResult = container.arView.hitTest(touchInView, types: .existingPlane)
//            guard let firstHitWTC = hitTestResult.first else { return }
//            let x = firstHitWTC.worldTransform.columns.3.x
//            let y  = firstHitWTC.worldTransform.columns.3.y
//            let z = firstHitWTC.worldTransform.columns.3.z
//
//            container.vm.alertObject = AlertObject(
//                title: "Add Node",
//                message: "Do you want to place virtual node here?",
//                onOk: {
//                    self.container.addElement(pos: [x, y, z])
//                },
//                onNo: {}
//            )
//            container.vm.isShowAlert = true
//            return
//        }
//        buttonTapped.onTapNode?(buttonTapped)
    }
}

extension ARCoordinator: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        guard let rawDepthImageBuffer = frame.sceneDepth?.depthMap else { return }
//        let rawDepthConfidenceImageBuffer = frame.sceneDepth?.confidenceMap
//        var cameraIntrinsic = frame.camera.intrinsics
//        let cameraResolution = frame.camera.imageResolution
//
//        let depthHeight = CVPixelBufferGetHeight(rawDepthImageBuffer)
//        let depthWidth = CVPixelBufferGetWidth(rawDepthImageBuffer)
//        let resizeScale = CGFloat(depthWidth) / CGFloat(CVPixelBufferGetWidth(frame.capturedImage))
//
//        let ratio = Float(cameraResolution.width) / Float(depthWidth)
//        cameraIntrinsic.columns.0[0] /= ratio
//        cameraIntrinsic.columns.1[1] /= ratio
//        cameraIntrinsic.columns.2[0] /= ratio
//        cameraIntrinsic.columns.2[1] /= ratio
//
//        var points: [SCNVector3] = []
//        let depthValues = frame.smoothedSceneDepth?.depthMap
//        for vv in 0..<depthHeight {
//            for uu in 0..<depthWidth {
//                //let z = -depthValues[uu + vv * depthWidth]
//                //let x = Float32(uu) / Float32(depthWidth) * 2.0 - 1.0
//                //let y = 1.0 - Float32(vv) / Float32(depthHeight) * 2.0
//                //points.append(SCNVector3(x, y, z))
//            }
//        }
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
