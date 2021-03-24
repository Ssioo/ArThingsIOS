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
    
    func setupGestures() {
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
            return
        }
        buttonTapped.tapAction?()
    }
    
    func addElements() {
        let greenBox = CustomBox(color: .green, position: [0.6, -1, -2]) {
            // When the AR Component has been clicked
            debugPrint("Click")
        }
        
        self.scene.anchors.append(greenBox)
    }
    
    func startAnalyzeFrame(url: Any) {
        self.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { }
            guard let snashaotAnchor = SnapshotAnchor(capturing: self)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: url,  options: [.atomic])
            } catch {
                fatalError()
            }
        }
    }
    
    func saveWorld() {
        
    }
}
