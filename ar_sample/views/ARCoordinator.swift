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
import MetalKit
import ModelIO
import QuickLook

class ARCoordinator: NSObject {
    var container: ARViewContainer
    var skipCnt = 0
    
    init(_ container: ARViewContainer) {
        self.container = container
    }
    
    func addElement(pos: SIMD3<Float>, onTap: (() -> Void)? = nil) {
        let greenBoxAnchor = CustomBox(color: .green, position: pos, onTap: onTap)
        container.arView.scene.anchors.append(greenBoxAnchor)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: container.arView), true else {
            return
        }

        guard let buttonTapped = container.arView.entity(at: touchInView) as? ARClickable else {
            let hitTestResult = container.arView.hitTest(touchInView, types: .existingPlane)
            guard let firstHitWTC = hitTestResult.first else { return }
            let x = firstHitWTC.worldTransform.columns.3.x
            let y  = firstHitWTC.worldTransform.columns.3.y
            let z = firstHitWTC.worldTransform.columns.3.z + 0.1

            debugPrint("Touch Point")
            container.mainVm.onAlertOk = {
                self.addElement(pos: [x, y, z]) {
                    debugPrint("click")
                }
                self.container.vm.addAnchor(anchor: firstHitWTC.anchor!, pos: [x, y, z])
            }
            container.mainVm.isShowAlert = true
            return
        }
        buttonTapped.tapAction?()
    }
    

    
}

extension ARCoordinator: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        skipCnt = skipCnt + 1
        if !skipCnt.isMultiple(of: 60) { return }
        container.arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }

            do {
                //let time = Date().timeIntervalSince1970
                //let mapUrl = try map.createPointCloudJSON().saveToFile(fileName: "rawFeatures\(time).txt") // Save Raw Feature Points
                let meshes = self.extractMesh(frame: frame)
                self.container.vm.saveMap(features: map.rawFeaturePoints, meshes: meshes)
                DispatchQueue.main.async {
                    debugPrint("Save complete")
                }
            } catch {
                debugPrint("Error")
            }
            
        }
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
    
    func extractMesh(frame: ARFrame) -> MDLAsset {
        // Fetch the default MTLDevice to initialize a MetalKit buffer allocator with
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Failed to get the system's default Metal device!")
        }
        // Using the Model I/O framework to export the scan, so we're initialising an MDLAsset object,
        // which we can export to a file later, with a buffer allocator
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        
        // Fetch all ARMeshAncors
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        
        // Convert the geometry of each ARMeshAnchor into a MDLMesh and add it to the MDLAsset
        for meshAncor in meshAnchors {
            
            // Some short handles, otherwise stuff will get pretty long in a few lines
            let geometry = meshAncor.geometry
            let vertices = geometry.vertices
            let faces = geometry.faces
            let verticesPointer = vertices.buffer.contents()
            let facesPointer = faces.buffer.contents()
            
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
            }
            
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
        return asset
        
        // Setting the path to export the OBJ file to
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let urlOBJ = documentsPath.appendingPathComponent("scan.obj")
//
//        // Exporting the OBJ file
//        if MDLAsset.canExportFileExtension("obj") {
//            do {
//                try asset.export(to: urlOBJ)
//
//            } catch let error {
//                fatalError(error.localizedDescription)
//            }
//        } else {
//            fatalError("Can't export OBJ")
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
