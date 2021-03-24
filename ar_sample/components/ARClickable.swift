//
//  ARClickable.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//

import RealityKit

class ARClickable: Entity, HasCollision, HasModel, HasTap {
    var tapAction: (() -> Void)?
    
    init(transform: Transform, model: ModelComponent, tapAction: (() -> Void)? = nil) {
        self.tapAction = tapAction
        super.init()
        self.model = model
        self.transform = transform
        self.generateCollisionShapes(recursive: false)
    }
    
    required init() {
        super.init()
    }
}
