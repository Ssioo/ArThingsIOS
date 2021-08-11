//
//  ARContentView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import SwiftUI
import ARKit
import RealityKit

struct ARContentView: View {
    var vm: ARViewModel
    @State private var isPickerShown = false
    @State private var arRooms: [String] = []
    @State private var currentRoom: String = ""
    @State private var hasFullScannedMap: Bool = false
    
    
    
    var body: some View {
        let arViewContainer: ARViewContainer = ARViewContainer(vm: vm)
        
        let pickerView: PickerSheetView = PickerSheetView(
            objs: $arRooms,
            onSelect: { value in
                isPickerShown = false
                if value == "New" {
                    vm.createNewARRoom()
                    return
                }
                currentRoom = value
                vm.currentRoom = value
                vm.isLoading = true
                vm.fetchARRoomsDataIndicesById(id: currentRoom) { arData, anchors in
                    vm.isLoading = false
                    hasFullScannedMap = arData != nil
                }
            },
            title: "Select AR Room",
            subtitle: "Which Room?",
            enableSheet: $isPickerShown
        )
        
        return ZStack(alignment: .bottom) {
            arViewContainer
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .center) {
                    CurrentRoomText(currentRoom: $currentRoom)
                    HStack {
                        Button(action: {
                            if $hasFullScannedMap.wrappedValue {
                                debugPrint("Fetching...")
                                vm.isLoading = true
                                vm.fetchARRoomsDataIndicesById(id: $currentRoom.wrappedValue) { res, anchors in
                                    vm.isLoading = false
                                    guard let data = res else {
                                        hasFullScannedMap = false
                                        return
                                    }
                                    hasFullScannedMap = true
                                    arViewContainer.reset(data: data, anchors: anchors)
                                }
                            } else {
                                debugPrint("Saving...")
                                vm.isLoading = true
                                arViewContainer.saveMap(currentRoom: currentRoom) {
                                    vm.isLoading = false
                                    vm.alertObject = AlertObject(
                                        title: "Success",
                                        message: "Success to Save world to remote",
                                        onOk: {},
                                        onNo: nil
                                    )
                                    vm.isShowAlert = true
                                }
                            }
                            
                        }, label: { LoadOrSaveButtonText(toLoad: $hasFullScannedMap) })
                        Button(action: {
                            vm.isLoading = true
                            vm.fetchARRooms {
                                vm.isLoading = false
                                self.arRooms = $0
                                isPickerShown = true
                            }
                        }, label: {
                            Text("Select room")
                                .foregroundColor(.white)
                                .frame(width: 160, height: 40, alignment: .center)
                                .background(Color.blue)
                        })
                    }
                }
            }
            pickerView
        }
    }
}

struct CurrentRoomText: View {
    @Binding var currentRoom: String
    var body: some View {
        Text("CurrentRoom: \(currentRoom)")
            .foregroundColor(.white)
        
    }
}

struct LoadOrSaveButtonText: View {
    @Binding var toLoad: Bool
    
    var body: some View {
        Text(toLoad ? "Load" : "Save")
            .foregroundColor(.white)
            .frame(width: 160, height: 40, alignment: .center)
            .background(Color.blue)
        
    }
}


struct ARViewContainer: UIViewRepresentable {
    var vm: ARViewModel
    
    let arView = ARView(frame: .zero)
    
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        initialize(context: context, arView: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    
    func saveMap(currentRoom: String, onFinish: (() -> Void)? = nil) {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { return }
            guard let frame = self.arView.session.currentFrame else { return }
            
            let meshes = frame.extractMesh()
            self.vm.saveMap(features: map.rawFeaturePoints, meshes: meshes, map: ARData(worldMap: map))
            self.vm.saveCurrentWorldDataToRemote(currentRoom: currentRoom, onFinish: onFinish)
        }
    }
    
    private func initialize(context: Context, arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        arView.debugOptions.insert(.showWorldOrigin)
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [])
        arView.session.delegate = context.coordinator

        arView.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        ))
        
    }
    
    func reset(data: ARData, anchors: [RemoteARAnchor]) {
        self.arView.session.pause()
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        
        self.arView.debugOptions.insert(.showWorldOrigin)
        self.arView.debugOptions.insert(.showSceneUnderstanding)
        guard let map = data.worldMap else { return }
        config.initialWorldMap = map
        
        self.arView.session.run(config, options: [.removeExistingAnchors, .resetSceneReconstruction, .resetTracking])

        anchors.forEach { anchor in
            self.addElement(pos: anchor.pos.toSIMD())
        }
    }
    
    func addElement(pos: SIMD3<Float>) {
        let onTap: (ARNode) -> Void = { node in
            
            // TODO: Harvesting 데이터 연결
            self.vm.getSolacleHarvDataAt(
                pos: pos,
                onPogress: { progress in
                    debugPrint(progress)
                },
                onRes: { res in
                    debugPrint(res)
                    var maxWatt = 0.0
                    var sumWatt = 0.0
            
                    res.forEach { key, value in
                        if value > maxWatt {
                            maxWatt = value
                        }
                        sumWatt = sumWatt + value
                    }
                    let avgWatt = sumWatt / 24
                    node.updateData(newData: "SUM: \(sumWatt)W, MAX: \(maxWatt)W, AVG: \(avgWatt)Wh")
                }
            )
        }
        let greenBoxAnchor = ARNode(pos: pos, onTapNode: onTap, onTapInfo: nil)
        self.arView.scene.anchors.append(greenBoxAnchor)
        self.vm.addAnchor(anchor: greenBoxAnchor, pos: pos) { node in
            node.removeFromParent()
        }
    }
}

