//
//  RemoteFileGenerator.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/06.
//

import Foundation
import ARKit
import RealityKit

struct RemoteFileGeneratorRequest {
    let content: String
    let name: String
    let format: String
    let type: String
    let path: String
}

struct ARData {
    var worldMap: ARWorldMap?
}

extension ARData: Codable {
    enum CodingKeys: String, CodingKey {
        case worldMap
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let worldMapData = try container.decode(Data.self, forKey: .worldMap)
        worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: worldMapData)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let worldMap = worldMap {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            try container.encode(colorData, forKey: .worldMap)
        }
    }
}
extension simd_float4x4: Collection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return 4 // for `sims_float4x4` it would be 4, number of columns
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }
}
extension simd_float3x3: Collection {
    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return 3 // for `sims_float4x4` it would be 4, number of columns
    }

    public func index(after i: Int) -> Int {
        return i + 1
    }
}
