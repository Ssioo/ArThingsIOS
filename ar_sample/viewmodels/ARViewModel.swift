//
//  ARViewModel.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import ARKit

class ARViewModel: ObservableObject {
    @Published var anchors: [ARAnchor: SIMD3<Float>] = [:]
    
    @Published var toSave: Bool = false
    var lastMapRawFearues: ARPointCloud? = nil
    var lastMeshes: MDLAsset? = nil
    
    func saveMap(features: ARPointCloud, meshes: MDLAsset) {
        self.lastMapRawFearues = features
        self.lastMeshes = meshes
        debugPrint("RawFeatures Saved")
    }
    
    func addAnchor(anchor: ARAnchor, pos: SIMD3<Float>) {
        self.anchors[anchor] = pos
        debugPrint(self.anchors)
    }
    
    func post() {
        let time = Date().timeIntervalSince1970
        APiModule.instance.postData(
            url: "/api/contents/\(time).obj",
            data: [:],
            onRes: { (res: EmptyRes) in
                debugPrint("success")
            },
            onErr: { err in
                debugPrint(err)
            }
        )
    }

}
