//
//  ApiModule.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import Alamofire


class APiModule {
    static let instance = APiModule()
    let BASE_URL = "https://ml.mobed.yonsei.ac.kr/user/ywcho/api"
    
    private init() {
        
    }
    
    func get<Res: Codable>(
        url: String,
        params: [String : String],
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        AF.request(
            "\(BASE_URL)\(url)",
            method: .get,
            parameters: params,
            encoder: JSONParameterEncoder.default,
            headers: ["Content-Type": "application/json"]
        )
            .validate(statusCode: 200..<300)
            .responseJSON { res in
                guard let jsonRes = res.value as? BaseResponse<Res> else {
                    onErr?(nil)
                    return
                }
                if jsonRes.status != 200 {
                    onErr?(jsonRes.message)
                    return
                }
                onRes?(jsonRes.data)            }
    }
    
    func post<Req: Codable, Res: Codable>(
        url: String,
        body: Req,
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        AF.request(
            "\(BASE_URL)\(url)",
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers: ["Content-Type":"application/json"]
        )
            .validate(statusCode: 200..<300)
            .responseJSON { res in
                guard let jsonRes = res.value as? BaseResponse<Res> else {
                    onErr?(nil)
                    return
                }
                if jsonRes.status != 200 {
                    onErr?(jsonRes.message)
                    return
                }
                onRes?(jsonRes.data)
            }
    }
    
    func postFile<Res: Codable>(
        url: String,
        fileUrl: URL,
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        AF.upload(fileUrl, to: "\(BASE_URL)\(url)")
            .validate(statusCode: 200..<300)
            .responseJSON { res in
                guard let jsonRes = res.value as? BaseResponse<Res> else {
                    onErr?(nil)
                    return
                }
                if jsonRes.status != 200 {
                    onErr?(jsonRes.message)
                    return
                }
                onRes?(jsonRes.data)
            }
    }
    
    func putData<Res: Codable>(
        url: String,
        data: [String : Data],
        onRes:((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) -> Void {
        AF.upload(multipartFormData: { multipartFormData in
            data.forEach { key, value in
                multipartFormData.append(value, withName: key)
            }
        }, to: "\(BASE_URL)\(url)", method: .put)
        .responseJSON { res in
            guard let jsonRes = res.value as? BaseResponse<Res> else {
                onErr?(nil)
                return
            }
            if jsonRes.status != 200 {
                onErr?(jsonRes.message)
                return
            }
            onRes?(jsonRes.data)
            
        }
    }
}
