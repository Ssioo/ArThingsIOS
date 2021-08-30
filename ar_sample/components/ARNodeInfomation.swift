//
//  ARNodeInfomation.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/05.
//

import Foundation
import SwiftUI
import RealityKit
import ARKit
import UIKit

struct ARNodeInformationSwiftUIView: View {
    var harvData: [Int: Double]
    var name: String
    var battery: Double
    
    var body: some View {
        let harvText = generateInfoText(data: harvData)
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center) {
                Text(self.name)
                    .font(.headline)
                    .frame(width: nil, height: 30, alignment: .center)
                LineChart(data: harvData.toLinePos())
                    .frame(width: 280, height: 100, alignment: .center)
                ZStack {
                    ProgressCircle(
                        progress:  0.3,
                        src: harvText.0,
                        color: Color(.sRGB, red: 1.0, green: 0.0, blue: 0.0)
                    )
                        .frame(width: 64, height: 64)
                        .position(x: 40, y: 50)
                    ProgressCircle(
                        progress:  0.6,
                        src: harvText.1,
                        color: Color(.sRGB, red: 0.0, green: 0.0, blue: 1.0)
                    )
                        .frame(width: 64, height: 64)
                        .position(x: 140, y: 50)
                    ProgressCircle(
                        progress:  0.6,
                        src: harvText.2,
                        color: Color(.sRGB, red: 0.0, green: 1.0, blue: 0.0)
                    )
                        .frame(width: 64, height: 64)
                        .position(x: 240, y: 50)
                    
                }
                .frame(width: 280, height: 100, alignment: .center)

            }.frame(width: 280, height: 250, alignment: .center)
            Battery(percentage: self.battery, color: .green)
                .frame(width: 30, height: 10, alignment: .topTrailing)
        }
        .padding(10.0)
        .background(Color.clear)
        .border(.black, width: 1)
    }
    
    func generateInfoText(data: [Int: Double]) -> (String, String, String) {
        var sum = 0.0
        var max = 0.0
        data.forEach { time, value in
            if value > max {
                max = value
            }
            sum = sum + value
        }
        let sumText = "\(String(format: "%.2f", sum / 1000.0 / 1000.0))W"
        let maxText = "\(String(format: "%.1f", max / 1000.0))mW"
        let avgText = "\(String(format: "%.1f", sum / 24.0 / 1000.0))mWh"
        return (sumText, maxText, avgText)
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
    
    }
}

struct Battery: View {
    var percentage: CGFloat
    var color: Color
    
    var body: some View {
        ZStack(alignment: .center) {
            HStack {
                RoundedRectangle(cornerRadius: 2.0)
                    .foregroundColor(self.color)
                    .frame(width: 36, height: 10)
            }
            Text("\(String(format: "%.f", self.percentage * 100))")
                .font(.caption2)
        }.frame(width: 30, height: 10)
        
        
    }
}

struct ProgressCircle: View {
    @State var progress: Double
    @State var src: String
    let color: Color
    let lineWidth: CGFloat = 8.0
    
    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.1)
                .foregroundColor(color)
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear)
            Text(src)
                .font(.headline)
                .bold()
        }
    }
}

struct LinePointPos: Identifiable {
    var id: UUID = UUID()
    var pos: Double
}

struct LineChart: View {
    @State var data: [LinePointPos]
    var body: some View {
        GeometryReader { gr in
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0.0, y: gr.size.height))
                    var count = 0.0
                    var lastY = 0.0
                    self.data.forEach { p in
                        count += 1.0
                        let nextX = count / Double(self.data.count) * Double(gr.size.width)
                        let nextY = (1.0 - p.pos) * Double(gr.size.height)
                        let cur = CGPoint(x: nextX, y: nextY)
                        
                        let curvePos = generateCurvePoint(
                            cur: cur,
                            last: CGPoint(
                                x: (count - 1) / Double(self.data.count) * Double(gr.size.width),
                                y: (1.0 - lastY) * Double(gr.size.height)
                            ))
                        path.addCurve(
                            to: cur,
                            control1: curvePos.0,
                            control2: curvePos.1
                        )
                        lastY = p.pos
                    }
                    path.addLine(to: CGPoint(x: gr.size.width, y: gr.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(
                    gradient: Gradient(
                        colors: [
                            .blue.opacity(0.8),
                            Color(red: 1.0, green: 0.0, blue: 1.0, opacity: 0.0)
                        ]),
                    startPoint: UnitPoint(x: 0.5, y: 0.1),
                    endPoint: UnitPoint(x: 0.5, y: 1.0)
                ))
                Path { path in
                    path.move(to: CGPoint(x: 0.0, y: gr.size.height))
                    var count = 0.0
                    var lastY = 0.0
                    self.data.forEach { p in
                        count += 1.0
                        let nextX = count / Double(self.data.count) * Double(gr.size.width)
                        let nextY = (1.0 - p.pos) * Double(gr.size.height)
                        let cur = CGPoint(x: nextX, y: nextY)
                        
                        let curvePos = generateCurvePoint(
                            cur: cur,
                            last: CGPoint(
                                x: (count - 1) / Double(self.data.count) * Double(gr.size.width),
                                y: (1.0 - lastY) * Double(gr.size.height)
                            ))
                        path.addCurve(
                            to: cur,
                            control1: curvePos.0,
                            control2: curvePos.1
                        )
                        lastY = p.pos
                    }
                }
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: UnitPoint(x: 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5, y: 0.6)
                ), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                Path { path in
                    path.move(to: CGPoint(x: 0.0, y: 0.0))
                    path.addLine(to: CGPoint(x: 0.0, y: gr.size.height))
                    path.addLine(to: CGPoint(x: gr.size.width, y: gr.size.height))
                }
                .stroke(Color.black, style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
                
            }
        }
    }
    
    func generateCurvePoint(cur: CGPoint, last: CGPoint) -> (CGPoint, CGPoint) {
        let yDeltaOffset = abs(last.y - cur.y) * 0.1
        let xDeltaOffset = abs(last.x - cur.x) * 0.5
        let curve1X = last.x + xDeltaOffset
        let curve1Y = cur.y + (last.y > cur.y ? yDeltaOffset : -yDeltaOffset)
        let curve2X = cur.x - xDeltaOffset
        let curve2Y = last.y + (last.y < cur.y ? yDeltaOffset : -yDeltaOffset)
        return (CGPoint(x: curve2X, y: curve2Y), CGPoint(x: curve1X, y: curve1Y))
    }
}
