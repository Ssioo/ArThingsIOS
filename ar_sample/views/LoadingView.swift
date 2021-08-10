//
//  LoadingView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/05.
//

import Foundation
import SwiftUI

struct LoadingView: View {
    @Binding var isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                Color(.systemBackground)
                    .opacity(0.38)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(3)
            }
        }
    }
}
