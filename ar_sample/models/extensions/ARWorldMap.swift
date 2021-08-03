//
//  ARWorldM ap.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/03.
//

import Foundation
import ARKit
import RealityKit

extension ARWorldMap {
    func createPointCloudJSON() -> String {
        var featurePoints: String = "{"
        let ids = self.rawFeaturePoints.identifiers
        let points = self.rawFeaturePoints.points
        
        for i in 0..<ids.count {
            let coord = points[i]
            featurePoints.append("\"\(ids[i])\"" + ":{")
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

extension simd_float4x4 {
    var position: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension Transform {
    static func * (left: Transform, right: Transform) -> Transform {
        return Transform(matrix: simd_mul(left.matrix, right.matrix))
    }
}

extension ARMeshGeometry {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
}
