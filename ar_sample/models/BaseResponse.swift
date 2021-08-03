//
//  BaseResponse.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/03.
//

import Foundation

struct BaseResponse<T: Codable>: Codable {
    let data: T
    let status: Int
    let message: String?
}

struct EmptyRes: Codable {
    let str: String?
}

struct EmptyReq: Codable {
    let str: String?
}
