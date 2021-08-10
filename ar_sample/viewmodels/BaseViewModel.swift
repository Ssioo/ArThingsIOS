//
//  BaseViewModel.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/05.
//

import Foundation

class BaseViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isShowAlert: Bool = false
    @Published var alertObject: AlertObject? = nil
    
}
