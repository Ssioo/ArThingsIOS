//
//  HasTap.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//

import Foundation

protocol HasTap {
    var tapAction: (() -> Void)? { get set }
}
