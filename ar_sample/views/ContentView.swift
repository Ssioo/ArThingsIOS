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
    @StateObject var vm = ARViewModel()

    var body: some View {
        return ZStack(alignment: .bottom) {   
            AlertTextView(
                isShowAlert: $vm.isShowAlert,
                alertObject: $vm.alertObject
            )
            ARContentView(vm: vm)
            LoadingView(isLoading: $vm.isLoading)
            LoadingProgressView(isLoading: $vm.isLoading, progress: $vm.progress)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

