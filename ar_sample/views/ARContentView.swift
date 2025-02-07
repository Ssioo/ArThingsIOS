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
                
                // Check if selected AR Map has already scanned data ?
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
            AimView()
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
                                // First, extract current ARMap from ARViewContainer's ARView's session
                                arViewContainer.saveMap(currentRoom: currentRoom) { res in
                                    if !res {
                                        // Failed
                                        vm.isLoading = false
                                        return
                                    }
                                    // Second, save extracted ARMap in ARViewModel to (Mobed ML) Server
                                    vm.saveCurrentWorldDataToRemote(currentRoom: currentRoom) { res in
                                        debugPrint("All cleard")
                                        vm.isLoading = false
                                        vm.alertObject = AlertObject(
                                            title: res ? "Success" : "Failure",
                                            message: "\(res ? "Success" : "Failed") to Save world to remote",
                                            onOk: {
                                                // Third, Reload full AR Rooms
                                                vm.fetchARRooms {
                                                    self.arRooms = $0
                                                }
                                                // Fourth, Reload current AR Map (Still in test)
                                                vm.fetchARRoomsDataIndicesById(id: $currentRoom.wrappedValue) { res, anchors in
                                                    vm.isLoading = false
                                                    guard let data = res else {
                                                        hasFullScannedMap = false
                                                        return
                                                    }
                                                    hasFullScannedMap = true
                                                    arViewContainer.reset(data: data, anchors: anchors)
                                                }
                                            },
                                            onNo: nil
                                        )
                                        vm.isShowAlert = true
                                    }
                                }
                            }
                            
                        }, label: { LoadOrSaveButtonText(toLoad: $hasFullScannedMap) })
                        Button(action: {
                            // On Every show up pickerView, fetch All ARRooms' indicies to latest data
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
    
    
    func saveMap(currentRoom: String, onFinish: ((Bool) -> Void)? = nil) {
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else {
                onFinish?(false)
                return
            }
            guard let frame = self.arView.session.currentFrame else {
                onFinish?(false)
                return
            }
            
            let skipMeshes = frame.extractMesh(true)
            self.vm.saveMap(features: map.rawFeaturePoints, meshes: skipMeshes, map: ARData(worldMap: map), skipMeshes)
            onFinish?(true)
        
        }
    }
    
    private func initialize(context: Context, arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        //config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.environmentTexturing = .automatic
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        //config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        arView.automaticallyConfigureSession = false
        //arView.debugOptions.insert(.showWorldOrigin)
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [])
        arView.session.delegate = context.coordinator

        arView.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        ))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleLongPress(_:))
        )
        longPressGestureRecognizer.numberOfTouchesRequired = 2
        longPressGestureRecognizer.allowableMovement = 600
        arView.addGestureRecognizer(longPressGestureRecognizer)
        
    }

    
    func reset(data: ARData, anchors: [RemoteARAnchor]) {
        debugPrint("How many calls of reset")
        vm.anchors.forEach { anchor, pos in
            anchor.removeFromParent()
        }
        self.vm.anchors.removeAll()
        self.arView.session.pause()
        
        let config = ARWorldTrackingConfiguration()
        self.arView.automaticallyConfigureSession = false
        self.arView.debugOptions.insert(.showWorldOrigin)
        self.arView.debugOptions.insert(.showSceneUnderstanding)
        //self.arView.debugOptions.insert(.showPhysics)
        //self.arView.environment.sceneUnderstanding.options = [.occlusion, .physics]


        guard let map = data.worldMap else {
            fatalError()
        }
        config.initialWorldMap = map
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        self.arView.session.run(config, options: [.removeExistingAnchors, .resetSceneReconstruction])

        anchors.forEach { anchor in
            self.addElement(pos: anchor.pos.toSIMD())
        }
    }
    
    func addButton(pos: SIMD3<Float>, text: String) {
        self.vm.previousArButton?.removeFromParent()
        let buttonNode = ARButton(text: text, pos: pos) { node in
            self.vm.alertObject = AlertObject(
                title: "Add Node",
                message: "Do you want to place virtual node here?",
                onOk: {
                    self.addElement(pos: pos)
                    node.removeFromParent()
                },
                onNo: {
                    node.removeFromParent()
                }
            )
            self.vm.isShowAlert = true
        }
        self.arView.scene.addAnchor(buttonNode)
        buttonNode.setPosition(pos, relativeTo: nil)
        
        self.vm.previousArButton = buttonNode
    }
    
    func addElement(pos: SIMD3<Float>) {
        let onTapInfo: (ARNode) -> Void = { node in
            vm.alertObject = AlertObject(
                title: "Delete Node",
                message: "Do you want to remove this node from server?",
                onOk: {
                    vm.isLoading = true
                    self.vm.deleteNode(node: node) { res in
                        vm.isLoading = false
                        vm.alertObject = AlertObject(
                            title: "Success",
                            message: "Success To Remove Node",
                            onOk: {},
                            onNo: nil)
                        vm.isShowAlert = true
                    }
                },
                onNo: {})
            vm.isShowAlert = true
        }
        let arNode = ARNode(
            onTapNode: { node in
                node.toggleInfo()
                // Harvesting 데이터 연결
                self.vm.isLoading = true
                self.vm.getSolacleHarvDataAt(
                    pos: pos,
                    onPogress: { progress in
                        vm.progress = progress
                    },
                    onRes: { res in
                        self.vm.isLoading = false
                        debugPrint(res)
                        node.updateData(newData: res)
                    }
                )
            },
            onTapInfo: onTapInfo
        )
        
        self.arView.scene.anchors.append(arNode)
        arNode.setPosition(pos, relativeTo: nil)
        self.vm.addAnchor(anchor: arNode, pos: pos) { node in
            node.removeFromParent()
        }
    }
}

