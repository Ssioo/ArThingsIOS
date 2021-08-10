//
// Created by 조연우 on 2021/07/27.
//

import Foundation

struct VirtualNode {
    var name: String
}

struct RemoteARMapIndex: Codable {
    let obj: String
    let map: String
    let anchors: [RemoteARAnchor]
}

struct RemoteARAnchor: Codable {
    let id: String
    let pos: RemoteARAnchorPosition
}

struct RemoteARAnchorPosition: Codable {
    let x: Float
    let y: Float
    let z: Float
}

extension RemoteARAnchorPosition {
    func toSIMD() -> SIMD3<Float> {
        return [self.x, self.y, self.z]
    }
}
