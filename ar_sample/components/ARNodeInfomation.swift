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

class ARNodeInfomationView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        var text = UILabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
