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
    
    let wattTextView: UILabel = {
        let container = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
        container.translatesAutoresizingMaskIntoConstraints = false
        container.textAlignment = .center
        container.textColor = .black
    
        return container
    }()
    
    let totalWattCircle: UIView = {
        let circle = UIView(frame: CGRect(x: 18, y: 18, width: 64, height: 64))
        circle.layer.cornerRadius = 32
        circle.layer.shadowOpacity = 0.9
        circle.layer.shadowRadius = 7
        circle.layer.backgroundColor = UIColor(Color(red: 0.25, green: 0.9, blue: 0.25, opacity: 0.38)).cgColor
        return circle
    }()
    
    let maxWattCircle: UIView = {
        let circle = UIView(frame: CGRect(x: 118, y: 18, width: 64, height: 64))
        circle.layer.cornerRadius = 32
        circle.layer.shadowOpacity = 0.9
        circle.layer.shadowRadius = 7
        circle.layer.backgroundColor = UIColor(Color(red: 0.9, green: 0.25, blue: 0.25, opacity: 0.38)).cgColor
        return circle
    }()
    
    let avgWattCircle: UIView = {
        let circle = UIView(frame: CGRect(x: 218, y: 18, width: 64, height: 64))
        circle.layer.cornerRadius = 32
        circle.layer.shadowOpacity = 0.9
        circle.layer.shadowRadius = 7
        circle.layer.backgroundColor = UIColor(Color(red: 0.25, green: 0.25, blue: 0.9, opacity: 0.38)).cgColor
        return circle
    }()
    
    func updateNewData(havData: [Int: Double]) {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        self.backgroundColor = .white
        self.layer.backgroundColor = UIColor.white.cgColor
        self.addSubview(totalWattCircle)
        self.addSubview(maxWattCircle)
        self.addSubview(avgWattCircle)
        //totalWattCircle.addSubview(wattTextView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
