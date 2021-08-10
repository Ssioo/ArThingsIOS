//
//  AlertView.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import SwiftUI

struct AlertObject {
    let title: String
    let message: String
    let onOk: () -> Void
    let onNo: (() -> Void)?
}

struct AlertTextView: UIViewControllerRepresentable {
    @Binding var isShowAlert: Bool
    @Binding var alertObject: AlertObject?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertTextView>) -> some UIViewController {
        return UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: UIViewControllerRepresentableContext<AlertTextView>) {
        if isShowAlert {
            let alert = UIAlertController(title: alertObject?.title ?? "", message: alertObject?.message, preferredStyle: .alert)
            if alertObject?.onNo != nil {
                alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: { _ in
                    // 취소버튼
                    alertObject?.onNo?()
                    alert.dismiss(animated: true, completion: nil)
                }))
            }
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                // 확인버튼
                alertObject?.onOk()
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
