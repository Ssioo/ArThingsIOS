//
//  ARContainer.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//


import RealityKit
import ARKit
import UIKit
import SwiftUI
import Combine
import CoreBluetooth

class ARContainer: ARView, ARSessionDelegate, ARCoachingOverlayViewDelegate {
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
    }
    
    @objc required dynamic init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func setupTapListener() {
        let tap = UITapGestureRecognizer(
            target: self,
            action: #selector(self.handleTap(_:))
        )
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: self), true else {
            return
        }

        guard let buttonTapped = self.entity(at: touchInView) as? ARClickable else {
            let hitTestResult = self.hitTest(touchInView, types: .existingPlane)
            guard let firstHitWTC = hitTestResult.first else { return }
            let x = firstHitWTC.worldTransform.columns.3.x
            let y  = firstHitWTC.worldTransform.columns.3.y
            let z = firstHitWTC.worldTransform.columns.3.z + 0.1
            debugPrint("Touch Point")
            let alertController = UIAlertController(title: "Add Node", message: "Do you want to place your new virtual Node?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { action in
                self.addElement(x: x, y: y, z: z) {
                    debugPrint("click")
                }
            })
            self.addElement(x: x, y: y, z: z) {
                debugPrint("click")
            }
            //present(alertController, animated: true, completion: nil)
            return
        }
        buttonTapped.tapAction?()
    }
    
    //let depthCloudPoints = []

    func addElement(x: Float, y: Float, z: Float, onTap: (() -> Void)? = nil) {
        let greenBoxAnchor = CustomBox(color: .green, position: [x, y, z], onTap: onTap)
        scene.anchors.append(greenBoxAnchor)
    }
    
    var skipCnt = 0
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        skipCnt = skipCnt + 1
        if !skipCnt.isMultiple(of: 20) { return }
        let rawDepthImage = frame.sceneDepth?.depthMap
        let rawDepthConfidenceImage = frame.sceneDepth?.confidenceMap
        let cameraIntrinsic = frame.camera.intrinsics
        let cameraResolution = frame.camera.imageResolution
    }
    
    public func save() {
        session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }

            do {
                let time = Date().timeIntervalSince1970
                try map.createPointCloudJSON().saveToFile(fileName: "rawFeatures\(time).txt") // Save Raw Feature Points

                //let data = try encoder.encode(arData)
                //let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                //try data.write(to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ARTest").appendingPathComponent("map.txt"), options: [.atomic])
                
                DispatchQueue.main.async {
                    debugPrint("Save complete")
                }
            } catch {
                debugPrint("Error")
            }
        }
    }
}


extension ARWorldMap {
    func createPointCloudJSON() -> String {
        var featurePoints: String = "{"
        let ids = self.rawFeaturePoints.identifiers
        let points = self.rawFeaturePoints.points
        
        for i in 0..<ids.count {
            let coord = points[i]
            featurePoints.append("\(ids[i])" + ":{")
            featurePoints.append("\"x\":" + "\(coord.x)")
            featurePoints.append(",\"y\":" + "\(coord.y)")
            featurePoints.append(",\"z\":" + "\(coord.z)" + "}")
            if i != ids.count - 1 {
                featurePoints.append(",")
            }
        }
        featurePoints.append("}")
        return featurePoints
    }
    
    func createDepthPointCloudJSON() -> String {
        return ""
    }
}


extension String {
    func saveToFile(fileName: String) throws {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = dir.appendingPathComponent(fileName)
        do {
            try self.write(to: filePath, atomically: true, encoding: .utf8)
        } catch let e {
            throw e
        }
    }
}
