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
    let BASE_URL = "https://ml.mobed.yonsei.ac.kr/user/akfgksmskdw/api"
    let JUPYTER_TOKEN = "a091046e330e455f8060196ab7a9aabf"
    
    let SOLACLE_URL = "http://165.132.105.197:9000"
    
    let sessionManager: Session = {
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return Session(configuration: config)
    }()
    
    
    private init() {
        
    }
    
    func get<Res: Codable>(
        of: Res.Type,
        url: String,
        params: [String:String],
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        sessionManager.request(
            "\(BASE_URL)\(url)",
            method: .get,
            parameters: params,
            encoder: URLEncodedFormParameterEncoder.default,
            headers:  [
                "Content-Type": "application/json",
                "Authorization": "token \(JUPYTER_TOKEN)"
            ]
        )
            .cacheResponse(using: ResponseCacher(behavior: .doNotCache))
            .validate(statusCode: 200..<300)
            .responseDecodable(of: of) { res in
                onRes?(res.value!)
            }
    }
    
    func getSolacle(
        url: String,
        params: [String : String],
        fileURL: URL,
        onProgress: ((Double) -> Void)? = nil,
        onFinish: (([Int:Double]) -> Void)? = nil
    ) {
        sessionManager.download(
            "\(SOLACLE_URL)\(url)",
            method: .get,
            parameters: params,
            encoder: URLEncodedFormParameterEncoder.default,
            to: { _, _ in
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
        )
        .cacheResponse(using: ResponseCacher(behavior: .doNotCache))
        .validate()
        .downloadProgress { progress in
            onProgress?(progress.fractionCompleted)
        }
        .response { res in
            let csv = fileURL.readCSV()
            onFinish?(csv)
        }
    }
    
    func post<Res: Codable>(
        of: Res.Type,
        url: String,
        body: [String : String],
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        sessionManager.request(
            "\(BASE_URL)\(url)",
            method: .post,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers:  [
                "Content-Type": "application/json",
                "Authorization": "token \(JUPYTER_TOKEN)"
            ]
        )
            .cacheResponse(using: ResponseCacher(behavior: .doNotCache))
            .validate(statusCode: 200..<300)
            .responseDecodable(of: of.self) { res in
                onRes?(res.value!)
            }
    }
    
    func put<Res: Codable>(
        of: Res.Type,
        url: String,
        body: [String:String],
        onRes: ((Res) -> Void)? = nil
    ) {
        sessionManager.request(
            "\(BASE_URL)\(url)",
            method: .put,
            parameters: body,
            encoder: JSONParameterEncoder.default,
            headers:  [
                "Content-Type": "application/json",
                "Authorization": "token \(JUPYTER_TOKEN)"
            ]
        )
        .cacheResponse(using: ResponseCacher(behavior: .doNotCache))
        .responseDecodable(of: of.self) { res in
            debugPrint(res.value)
            onRes?(res.value!)
        }
    }
    
    func postFile<Res: Codable>(
        url: String,
        fileUrl: URL,
        onRes: ((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        sessionManager.upload(
            fileUrl,
            to: "\(BASE_URL)\(url)",
            headers:  [
                "Content-Type": "application/json",
                "Authorization": "token \(JUPYTER_TOKEN)"
            ]
        )
            .validate(statusCode: 200..<300)
            .responseJSON { res in
                guard let jsonRes = res.value as? Res else {
                    onErr?(nil)
                    return
                }
                onRes?(jsonRes)
            }
    }
    
    func putData<Res: Codable>(
        url: String,
        data: [String : Data],
        onRes:((Res) -> Void)? = nil,
        onErr: ((String?) -> Void)? = nil
    ) {
        sessionManager.upload(
            multipartFormData: { multipartFormData in
                data.forEach { key, value in
                    multipartFormData.append(value, withName: key)
                }
            },
            to: "\(BASE_URL)\(url)",
            method: .put,
            headers:  [
                "Content-Type": "application/json",
                "Authorization": "token \(JUPYTER_TOKEN)"
            ]
        )
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
