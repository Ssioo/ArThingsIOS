//
//  ARWorldM ap.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/03.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI
import MetalKit
import ModelIO

extension ARPointCloud {
    func toJSON() -> String {
        var featurePoints: String = "{"
        let ids = self.identifiers
        let points = self.points
        
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

extension SIMD3 where Scalar == Float {
    func distanceTo(other: SIMD3<Float>) -> Float {
        return sqrt(pow(self.x - other.x, 2) + pow(self.y - other.y, 2) + pow(self.z - other.z, 2))
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

extension UIView {
    func snapshot() -> CGImage? {
        
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        let uiImage = renderer.image { context in
            self.layer.render(in: context.cgContext)
        }
        guard let ciImage = CIImage(image: uiImage) else { return nil }
        return CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)
    }
}

extension View {
    func snapshot(size: CGSize) -> CGImage? {
        let controller = UIHostingController(rootView: self)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        let image = controller.view.snapshot()
        return image
    }
}

extension ARFrame {
    func extractMesh(_ classFind: Bool = false) -> MDLAsset {
        // Fetch the default MTLDevice to initialize a MetalKit buffer allocator with
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to get the system's default Metal device!")
        }
        // Using the Model I/O framework to export the scan, so we're initialising an MDLAsset object,
        // which we can export to a file later, with a buffer allocator
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        
        // Fetch all ARMeshAncors
        let meshAnchors = self.anchors.compactMap({ $0 as? ARMeshAnchor })
        // Convert the geometry of each ARMeshAnchor into a MDLMesh and add it to the MDLAsset
        
        var meshString = "["
        for meshAncor in meshAnchors {
            debugPrint("skipped Anchor: ", meshAncor)
            // Some short handles, otherwise stuff will get pretty long in a few lines
            let geometry = meshAncor.geometry
        
            let vertices = geometry.vertices
            let faces = geometry.faces
            let verticesPointer = vertices.buffer.contents()
            let facesPointer = faces.buffer.contents()
            let meshAncorPos = meshAncor.transform.position
            
            let classification = geometry.classificationOf(faceWithIndex: 0)
            meshString += "{\"id\": \"\(meshAncor.identifier)\", \"class\": \"\(classification.description)\", \"transform\": {\"x\": \(meshAncorPos.x), \"y\": \(meshAncorPos.y), \"z\": \(meshAncorPos.z)},"
            var vertexString =  "\"vertices\": ["
            
            // Converting each vertex of the geometry from the local space of their ARMeshAnchor to world space
            for vertexIndex in 0..<vertices.count {
                
                // Extracting the current vertex with an extension method provided by Apple in Extensions.swift
                let vertex = geometry.vertex(at: UInt32(vertexIndex))
            
                
                // Building a transform matrix with only the vertex position
                // and apply the mesh anchors transform to convert into world space
                var vertexLocalTransform = matrix_identity_float4x4
                vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
                let vertexWorldPosition = (meshAncor.transform * vertexLocalTransform).position
                
                // Writing the world space vertex back into it's position in the vertex buffer
                let vertexOffset = vertices.offset + vertices.stride * vertexIndex
                let componentStride = vertices.stride / 3
                verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
                
                
                let newVertexElementString = "{\"x\": \(vertexWorldPosition.x), \"y\": \(vertexWorldPosition.y), \"z\": \(vertexWorldPosition.z)}"
                vertexString += newVertexElementString + ","
            }
            meshString += vertexString.dropLast() + "],"
            
            var faceString = "\"faces\": ["
            var classString = "\"classes\": ["
            for faceIdx in 0..<faces.count {
                let faceVertices = geometry.vertexIndicesOf(faceWithIndex: faceIdx)
                let classFace = geometry.classificationOf(faceWithIndex: faceIdx)
                classString += "\(classFace.rawValue),"
                do {
                    let faceVerticesJson = String(data: try JSONEncoder().encode(faceVertices), encoding: .utf8)!
                    faceString += faceVerticesJson + ","
                } catch {
                }
            }
            meshString += faceString.dropLast() + "]},"
            meshString += classString.dropLast() + "]},"
            
            
            // Initializing MDLMeshBuffers with the content of the vertex and face MTLBuffers
            let byteCountVertices = vertices.count * vertices.stride
            let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
            let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
            let indexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: byteCountFaces, deallocator: .none), type: .index)
            
            // Creating a MDLSubMesh with the index buffer and a generic material
            let indexCount = faces.count * faces.indexCountPerPrimitive
            let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
            let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)
            
            // Creating a MDLVertexDescriptor to describe the memory layout of the mesh
            let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
            let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: meshAncor.geometry.vertices.stride)
            
            // Finally creating the MDLMesh and adding it to the MDLAsset
            let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: meshAncor.geometry.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
            
            asset.add(mesh)
        }
        meshString = meshString.dropLast() + "]"
        
        // Save MeshString
        do {
            let fileName = "\(Date().timeIntervalSince1970)_meshtxt.txt"
            try meshString.saveToFile(fileName: fileName)
        } catch {
            
        }
        
        
        return asset
    }}

extension URL {
    func readCSV() -> [Int:Double] {
        do {
            let content = try String(contentsOf: self)
            var result: [Int : Double] = [:]
            content.components(separatedBy: "\n")
                .forEach { row in
                    let val = row.components(separatedBy: ",")
                    debugPrint(val)
                    if val.count != 2 {
                        return
                    }
                    result[Int(val[0])!] = Double(val[1])
                }
            return result
        } catch {
            return [:]
        }
    }
}

extension Dictionary where Key == Int, Value == Double {
    func toLinePos() -> [LinePointPos] {
        var max = 0.0
        var min = 100000.0
        forEach { key, value in
            if value > max {
                max = value
            }
            if value < min {
                min = value
            }
        }
        var res = map { key, value in
            (key, LinePointPos(pos: value / abs(max - min)))
        }
        res.sort(by: {$0.0 < $1.0})
        return res.map { $0.1 }
    }
}

extension Entity {
    func lookatMe(_ me: SIMD3<Float>, up: SIMD3<Float>? = nil) {
        if up != nil {
            self.look(at: me, from: self.position(relativeTo: nil), upVector: up!, relativeTo: nil)
        } else {
            self.look(at: me, from: self.position(relativeTo: nil), relativeTo: nil)
            
        }
        
    }
}

extension ARMeshGeometry {
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        let classificationAddress = classification.buffer.contents().advanced(by: index)
        let classificationValue = Int(classificationAddress.assumingMemoryBound(to: UInt8.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }
    
    func vertexIndicesOf(faceWithIndex index: Int) -> [Int] {
        let indicesPerFace = faces.indexCountPerPrimitive
        let facesPointer = faces.buffer.contents()
        var vertexIndices = [Int]()
        for offset in 0..<indicesPerFace {
            let vertexIndexAddress = facesPointer.advanced(by: (index * indicesPerFace + offset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(Int(vertexIndexAddress.assumingMemoryBound(to: UInt32.self).pointee))
        }
        return vertexIndices
    }
}

extension ARMeshClassification {
    var description: String {
        switch self {
            case .ceiling: return "Ceiling"
            case .door: return "Door"
            case .floor: return "Floor"
            case .seat: return "Seat"
            case .table: return "Table"
            case .wall: return "Wall"
            case .window: return "Window"
            case .none: return "None"
            @unknown default: return "Unknown"
        }
    }
    var color: UIColor {
        switch self {
            case .ceiling: return .red
            case .door: return .green
            case .floor: return .blue
            case .seat: return .cyan
            case .table: return .magenta
            case .wall: return .yellow
            case .window: return .black
            case .none: return .systemOrange
            @unknown default: return .white
        }
    }
}
