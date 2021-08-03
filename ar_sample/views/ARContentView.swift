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
    var mainVm: MainViewModel
    var vm: ARViewModel
    
    var body: some View {
        let arViewContainer = ARViewContainer(vm: vm, mainVm: mainVm)
        return ZStack {
            HStack {
                arViewContainer
                Button(
                    action: { vm.post() },
                    label: { Text("Save").foregroundColor(.white) }
                 )
                    .frame(width: 160, height: 40, alignment: .bottom)
                    .background(Color.blue)
            }
        }
    }
}


struct ARViewContainer: UIViewRepresentable {
    var vm: ARViewModel
    var mainVm: MainViewModel
    
    var arView = ARView(frame: .zero)
    
    func makeCoordinator() -> ARCoordinator {
        ARCoordinator(self)
    }
    
    func makeUIView(context: Context) -> ARView {
        initialize(context: context, arView: arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    

    
    private func initialize(context: Context, arView: ARView) {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [])
        arView.session.delegate = context.coordinator

        arView.addGestureRecognizer(UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        ))
        
    }
    
    
}

