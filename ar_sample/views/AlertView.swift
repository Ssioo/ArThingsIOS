//
//  AlertView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import SwiftUI

struct AlertTextView: UIViewControllerRepresentable {
    @Binding var isShowAlert: Bool
    @Binding var onOk: () -> Void
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertTextView>) -> some UIViewController {
        return UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<AlertTextView>) {
        if isShowAlert {
            let alert = UIAlertController(title: "Add Node", message: "Do you want to place virtual node here?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { _ in
                // 취소버튼
                alert.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                // 확인버튼
                onOk()
                alert.dismiss(animated: true, completion: nil)
            }))
            DispatchQueue.main.async {
                uiViewController.present(alert, animated: true) {
                    isShowAlert = false
                }
            }
        }
    }
}
