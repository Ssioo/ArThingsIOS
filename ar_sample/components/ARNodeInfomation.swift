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
    
    let totalWattTextView: UILabel = {
        let container = UILabel(frame: CGRect(x: 0, y: 20, width: 80, height: 30))
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
    
    let maxWattTextView: UILabel = {
        let container = UILabel(frame: CGRect(x: 0, y: 20, width: 80, height: 30))
        container.translatesAutoresizingMaskIntoConstraints = false
        container.textAlignment = .center
        container.textColor = .black
        return container
    }()
    
    let maxWattCircle: UIView = {
        let circle = UIView(frame: CGRect(x: 118, y: 18, width: 64, height: 64))
        circle.layer.cornerRadius = 32
        circle.layer.shadowOpacity = 0.9
        circle.layer.shadowRadius = 7
        circle.layer.backgroundColor = UIColor(Color(red: 0.9, green: 0.25, blue: 0.25, opacity: 0.38)).cgColor
        return circle
    }()
    
    let avgWattTextView: UILabel = {
        let container = UILabel(frame: CGRect(x: 0, y: 20, width: 80, height: 30))
        container.textAlignment = .center
        container.textColor = .black
        return container
    }()
    
    let avgWattCircle: UIView = {
        let circle = UIView(frame: CGRect(x: 218, y: 18, width: 64, height: 64))
        circle.layer.cornerRadius = 32
        circle.layer.shadowOpacity = 0.9
        circle.layer.shadowRadius = 7
        circle.layer.backgroundColor = UIColor(Color(red: 0.25, green: 0.25, blue: 0.9, opacity: 0.38)).cgColor
        return circle
    }()
    
    func updateNewData(havData: [Int: Double]) -> ARNodeInfomationView {
        var sum = 0.0
        var max = 0.0
        havData.forEach { time, value in
            if value > max {
                max = value
            }
            sum = sum + value
        }
        self.totalWattTextView.text = "\(String(format: "%.2f", sum / 1000.0 / 1000.0))W"
        self.maxWattTextView.text = "\(String(format: "%.1f", max / 1000.0))mW"
        self.avgWattTextView.text = "\(String(format: "%.1f", sum / 24.0 / 1000.0))mWh"
        return self
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
        totalWattCircle.addSubview(totalWattTextView)
        avgWattCircle.addSubview(avgWattTextView)
        maxWattCircle.addSubview(maxWattTextView)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
