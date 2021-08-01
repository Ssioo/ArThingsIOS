//
//  CustomBox.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//

import SwiftUI
import RealityKit

class CustomBox: ARClickable, HasAnchoring {
    required init(color: UIColor, onTap: (() -> Void)? = nil) {
        super.init(
            transform: Transform(),
            model: ModelComponent(
                mesh: .generateBox(size: [0.1, 0.1, 0.1]),
                materials: [SimpleMaterial(
                    color: color,
                    isMetallic: false
                )]),
            tapAction: onTap
        )
        
        self.components[CollisionComponent] = CollisionComponent(
            shapes: [.generateBox(size: [0.1, 0.1, 0.1])],
            mode: .trigger,
            filter: .sensor
        )
        
        self.generateCollisionShapes(recursive: true)
    }
    
    convenience init(color: UIColor, position: SIMD3<Float>, onTap: (() -> Void)? = nil) {
        self.init(color: color, onTap: onTap)
        self.position = position
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
}
