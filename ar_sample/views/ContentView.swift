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
    @StateObject var vm = MainViewModel()
    @StateObject var arVm = ARViewModel()

    var body: some View {
        return ZStack(alignment: .bottom) {
            AlertTextView(
                isShowAlert: $vm.isShowAlert,
                onOk: $vm.onAlertOk
            )
            ARContentView(mainVm: vm, vm: arVm)
        }
        .edgesIgnoringSafeArea(.all)
    }
}



#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
