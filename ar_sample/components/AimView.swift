//
//  AimView.swift
//  AimView
//
//  Created by 조연우 on 2021/08/25.
//

import Foundation
import SwiftUI

struct AimView: View {
    var body: some View {
        GeometryReader { gr in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 15))
                    path.addLine(to: CGPoint(x: 30, y: 15))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                Path { path in
                    path.move(to: CGPoint(x: 15, y: 0))
                    path.addLine(to: CGPoint(x: 15, y: 30))
                }
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                
            }
            .frame(width: 30, height: 30, alignment: .center)
            .position(x: gr.size.width / 2, y: gr.size.height / 2)
        }
    }
}
