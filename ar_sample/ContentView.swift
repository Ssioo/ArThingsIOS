//
//  ContentView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject var viewModel = ContentViewModel()
    
    var arViewContainer = ARViewContainer()

    var body: some View {
        return ZStack {
            Button(action: {
                arViewContainer.arView.save()
            }, label: {
                Text("Save")
            })
            arViewContainer
        }
        .edgesIgnoringSafeArea(.all)
    }
}

class ContentViewModel: ObservableObject {
    @Published var temp = ""

    
}

struct ARViewContainer: UIViewRepresentable {
    
    public let arView = ARContainer(frame: .zero)
    
    func makeUIView(context: Context) -> ARContainer {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .meshWithClassification
        config.frameSemantics = [.sceneDepth, .smoothedSceneDepth]
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(config, options: [])
        
        
        arView.setupTapListener()
        
        arView.session.delegate = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARContainer, context: Context) {}
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
