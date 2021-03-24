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
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARContainer {
        
        let arView = ARContainer(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        config.sceneReconstruction = .meshWithClassification
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.session.run(c onfig, options: [])
        

        arView.setupGestures()
        arView.addElements()
        arView.session.delegate = arView
        
        arView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap else { }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) else {}
            debugPrint(data)
        }
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARContainer, context: Context) {}
    
    func saveWorld() {
        arv
    }
    
}


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
