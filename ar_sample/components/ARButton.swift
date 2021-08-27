//
//  ARButton.swift
//  ARButton
//
//  Created by 조연우 on 2021/08/24.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit

class ARButton: Entity, HasAnchoring, HasCollision, HasModel {
    var onTap: ((ARButton) -> Void)? = nil
    
    convenience init(text: String, pos: SIMD3<Float>, onTap: ((ARButton) -> Void)? = nil) {
        self.init()
        self.onTap = onTap
        self.transform = Transform()
        
        do {
            var customViewMaterial = SimpleMaterial()
            let view = ARButtonBase(btnText: text)
            
            customViewMaterial.baseColor = try MaterialColorParameter.texture(
                .generate(
                    from: view.uiImage()!,
                    options: TextureResource.CreateOptions(
                        semantic: nil,
                        mipmapsMode: .allocateAndGenerateAll
                    )
                ))
            self.model = ModelComponent(
                mesh: .generateBox(size: [0.18, 0.04, 0.001]),
                materials: [customViewMaterial]
            )
            self.components[CollisionComponent] = CollisionComponent(
                shapes: [.generateBox(size: [0.18, 0.04, 0.001])],
                mode: .trigger,
                filter: .sensor
            )
            self.name = "ARButton_\(UUID().uuidString)"
            self.generateCollisionShapes(recursive: false)
            
        } catch {
            fatalError()
        }
        self.position = pos
        
    }
    
    required init() {
        super.init()
    }
}

struct ARButtonBase: View {
    var btnText: String
    
    var body: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 10.0)
                .fill(.white)
            Text(btnText)
                .foregroundColor(.black)
        }
        .frame(width: 180, height: 40, alignment: .center)
    }
    
    func uiImage() -> CGImage? {
       let controller = UIHostingController(rootView: self)
       let view = controller.view
       let targetSize = controller.view.intrinsicContentSize
       view?.bounds = CGRect(origin: .zero, size: targetSize)
       view?.backgroundColor = .systemBackground
       let renderer = UIGraphicsImageRenderer(size: targetSize)
       let uiImage = renderer.image { _ in
         view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
       }
        guard let ciImage = CIImage(image: uiImage) else { return nil }
        return CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent)
    
    }}
