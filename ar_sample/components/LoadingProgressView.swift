//
//  LoadingProgressView.swift
//  LoadingProgressView
//
//  Created by mobed on 2021/08/17.
//

import Foundation
import SwiftUI

struct LoadingProgressView: View {
    @Binding var isLoading: Bool
    @Binding var progress: Double
    
    var body: some View {
        if isLoading {
            GeometryReader { gr in
                VStack(alignment: .center) {
                    Text("\(progress)% Loading...")
                        .foregroundColor(.black)
                }.background(RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(Color.white).shadow(radius: 1))
                    .position(x: gr.size.width / 2 ,y: 20)
            }
        }
    }
}
