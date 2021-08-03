//
//  MainViewModel.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import ARKit

class MainViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isShowAlert: Bool = false
    @Published var onAlertOk: () -> Void  = {}
    
}
