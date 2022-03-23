//
//  ARViewModel.swift
//  ar_sample
//
//  Created by 조연우 on 2021/08/02.
//

import Foundation
import ARKit

class ARViewModel: BaseViewModel {
    @Published var anchors: [ARNode: SIMD3<Float>] = [:]
    @Published var arRooms: [String] = []
    var currentRoom: String = ""
    

    var lastMapRawFearues: ARPointCloud? = nil
    var lastMeshes: MDLAsset? = nil
    var lastTestMeshes: MDLAsset? = nil
    var lastARData: ARData? = nil
    
    var lastSavedARRemoteData: RemoteARMapIndex? = nil
    
    var previousArButton: ARButton? = nil
    
   override init() {
        super.init()
        self.fetchARRooms()
    }
    
    func saveMap(features: ARPointCloud, meshes: MDLAsset, map: ARData, _ skipMeshes: MDLAsset) {
        self.lastMapRawFearues = features
        self.lastMeshes = meshes
        self.lastARData = map
        self.lastTestMeshes = skipMeshes
        debugPrint("RawFeatures Saved")
    }
    
    func addAnchor(anchor: ARNode, pos: SIMD3<Float>, onFail: ((ARNode) -> Void)? = nil) {
        self.anchors[anchor] = pos
        debugPrint(self.anchors)
        self.updateAnchorsToRemote(
            currentRoomPath: self.currentRoom,
            onFail: {
                self.anchors.removeValue(forKey: anchor)
                onFail?(anchor)
            })
    }
    
    func fetchARRooms(onFinish: (([String]) -> Void)? = nil) {
        APiModule.instance.get(
            of: RemoteDirContent.self,
            url: "/contents/arthings",
            params: [:],
            onRes: { res in
                self.arRooms = res.content?.map { $0.name } ?? []
                onFinish?(self.arRooms)
            },
            onErr: {
                debugPrint($0 ?? "")
            }
        )
    }
    
    func fetchARRoomsDataIndicesById(id: String, onFinish: ((ARData?, [RemoteARAnchor]) -> Void)? = nil) {
        APiModule.instance.get(
            of: RemotePureFileContent.self,
            url: "/contents/arthings/\(id)/index.json",
            params: [:],
            onRes: { res in
                if res.content == "" || res.content == nil {
                    onFinish?(nil, [])
                    return
                }
                do {
                    guard let data = res.content?.data(using: .utf8) else { return }
                    let json = try JSONDecoder().decode(RemoteARMapIndex.self, from: data)
                    self.lastSavedARRemoteData = json
                    self.fetchARRoomMap(
                        roomId: id,
                        mapPath: json.map,
                        onFinish: {
                            onFinish?($0, json.anchors)
                        })
                } catch {
                    onFinish?(nil, [])
                }
            },
            onErr: {
                debugPrint($0 ?? "")
                onFinish?(nil, [])
            }
        )
    }
    
    
    func fetchARRoomMap(roomId: String, mapPath: String, onFinish: ((ARData?) -> Void)? = nil) {
        APiModule.instance.get(
            of: RemotePureFileContent.self,
            url: "/contents/arthings/\(roomId)/\(mapPath)",
            params: [:],
            onRes: { res in
                guard let mapString = res.content else {
                    onFinish?(nil)
                    return
                }
               
                do {
                    let saved = try JSONDecoder().decode(ARData.self, from: mapString.data(using: .utf8)!)
                    onFinish?(saved)
                } catch {
                    onFinish?(nil)
                }
                
            }
        )
    }
    
    func getSolacleHarvDataAt(pos: SIMD3<Float>, onPogress: ((Double) -> Void)? = nil,onRes: (([Int: Double]) -> Void)? = nil) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = dir.appendingPathComponent("harv.csv")
        APiModule.instance
            .getSolacle(
                url: "/download",
                params: [
                    "room": "806",
                    "x": "\(pos.x)",
                    "y": "\(pos.y)",
                    "z": "\(pos.z)"
                ],
                fileURL: filePath,
                onProgress: onPogress,
                onFinish: onRes
            )
    }
    
    func deleteNode(node: ARNode, onFinish: ((Bool) -> Void)? = nil) {
        let lastPos = self.anchors.removeValue(forKey: node)
        self.updateAnchorsToRemote(
            currentRoomPath: self.currentRoom,
            onFail: {
                self.anchors[node] = lastPos
                onFinish?(false)
            },
            onSuccess: {
                onFinish?(true)
                node.removeFromParent()
            }
        )
    }
    
    
    func createNewARRoom() {
        let newARRoomId = UUID.init().uuidString
        
        APiModule.instance.put(
            of: RemotePureFileContent.self,
            url: "/contents/arthings/\(newARRoomId)",
            body: [
                "content":"",
                "name": "\(newARRoomId)",
                "format": "text",
                "type": "directory",
                "path": "arthings/\(newARRoomId)"
            ],
            onRes: { res in
                APiModule.instance.put(
                    of: RemotePureFileContent.self,
                    url: "/contents/arthings/\(newARRoomId)/index.json",
                    body: [
                        "content": "",
                        "name": "index.json",
                        "format": "text",
                        "type": "file",
                        "path": "arthings/\(newARRoomId)/index.json"
                    ],
                    onRes: { res in
                        self.fetchARRooms()
                    }
                )
            }
        )
    }
    
    func saveCurrentWorldDataToRemote(currentRoom: String, onFinish: ((Bool) -> Void)? = nil) {
        // file 생성
        let currentRoomPath = currentRoom
        
        if currentRoom == "" {
            onFinish?(false)
            return
        }
        let time = Date().timeIntervalSince1970
        let usdPath = currentRoomPath+"\(time).usd"
        let objPath = currentRoomPath+"\(time).obj"
        let obj2Path = currentRoomPath+"\(time)2.obj"
        let mapPath = currentRoomPath+"\(time)_map.json"
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let urlOBJ = documentsPath.appendingPathComponent(objPath)
        let url2OBJ = documentsPath.appendingPathComponent(obj2Path)
        let urlUSD = documentsPath.appendingPathComponent(usdPath)
        
        // Exporting the USD file
        if MDLAsset.canExportFileExtension("usd") {
            do {
                try self.lastMeshes?.export(to: urlUSD)
            }
            catch {
                onFinish?(false)
                return
            }
        }
        if MDLAsset.canExportFileExtension("obj") {
            do {
                try self.lastMeshes?.export(to: urlOBJ)
                let meshString = try String(contentsOf: urlOBJ, encoding: .utf8)
                try FileManager.default.removeItem(at: urlOBJ)
                
                try self.lastTestMeshes?.export(to: url2OBJ)
                let mesh2String = try String(contentsOf: url2OBJ, encoding: .utf8)
                try FileManager.default.removeItem(at: url2OBJ)
                var cleared: [Bool] = [false, false, false, false]
                
                guard let mapJson = String(data: try JSONEncoder().encode(self.lastARData!), encoding: .utf8) else {
                    onFinish?(false)
                    return
                }
        
                
                // Meshes
                APiModule.instance
                    .put(
                        of: RemotePureFileContent.self,
                        url: "/contents/arthings/\(currentRoomPath)/\(objPath)",
                        body: [
                            "content":"\(meshString)",
                            "name": "\(objPath)",
                            "format": "text",
                            "type": "file",
                            "path": "arthings/\(currentRoomPath)/\(objPath)"
                        ],
                        onRes: { res in
                            cleared[0] = true
                            debugPrint(cleared)
                            if cleared.allSatisfy({ $0 == true }) {
                            
                                onFinish?(true)
                            }
                        }
                    )
                
                // Meshes
                APiModule.instance
                    .put(
                        of: RemotePureFileContent.self,
                        url: "/contents/arthings/\(currentRoomPath)/\(obj2Path)",
                        body: [
                            "content":"\(mesh2String)",
                            "name": "\(obj2Path)",
                            "format": "text",
                            "type": "file",
                            "path": "arthings/\(currentRoomPath)/\(obj2Path)"
                        ],
                        onRes: { res in
                            cleared[3] = true
                            debugPrint(cleared)
                            if cleared.allSatisfy({ $0 == true }) {
                            
                                onFinish?(true)
                            }
                        }
                    )
                
                // Map BAse64
                APiModule.instance
                    .put(
                        of: RemotePureFileContent.self,
                        url: "/contents/arthings/\(currentRoomPath)/\(mapPath)",
                        body: [
                            "content":"\(mapJson)",
                            "name": "\(mapPath)",
                            "format": "text",
                            "type": "file",
                            "path": "arthings/\(currentRoomPath)/\(objPath)"
                        ],
                        onRes: { res in
                            cleared[1] = true
                            debugPrint(cleared)
                            if cleared.allSatisfy({ $0 == true }) {
                                onFinish?(true)
                            }
                        }
                    )//put
                // Indexing
                APiModule.instance
                    .put(
                        of: RemotePureFileContent.self,
                        url: "/contents/arthings/\(currentRoomPath)/index.json",
                        body: [
                            "content":"\(makeInitialARRoomJSON(objPath: objPath, mapPath: mapPath))",
                            "name": "index.json",
                            "format": "text",
                            "type": "file",
                            "path": "arthings/\(currentRoomPath)/index.json"
                        ],
                        onRes: { res in
                            cleared[2] = true
                            debugPrint(cleared)
                            if cleared.allSatisfy({ $0 == true }) {
                                onFinish?(true)
                            }
                        }
                    )// put
            }//do
            catch let error {
                fatalError(error.localizedDescription)
            }//catch
        }//export?
        else {
            fatalError("Can't export OBJ")
        }//else
        
    }// func saveCurrentWorldDataToRemote
    
    func updateAnchorsToRemote(currentRoomPath: String, onFail: (() -> Void)? = nil, onSuccess: (() -> Void)? = nil) {
        // Indexing
        guard let lastMap = self.lastSavedARRemoteData else {
            debugPrint("No Map")
            onFail?()
            return
        }
        self.isLoading = true
        APiModule.instance
            .put(
                of: RemotePureFileContent.self,
                url: "/contents/arthings/\(currentRoomPath)/index.json",
                body: [
                    "content":"\(makeInitialARRoomJSON(objPath: lastMap.obj, mapPath: lastMap.map))",
                    "name": "index.json",
                    "format": "text",
                    "type": "file",
                    "path": "arthings/\(currentRoomPath)/index.json"
                ],
                onRes: { res in
                    self.isLoading = false
                    debugPrint(res)
                    onSuccess?()
                }
            )//put
    }
    
    
    func makeInitialARRoomJSON(objPath: String, mapPath: String) -> String {
        let anchors = self.anchors.map { (anchor, pos) -> RemoteARAnchor in
            var anchorId = anchor.name
            if anchor.name == "" {
                anchorId = UUID().uuidString
            }
            return RemoteARAnchor(id: anchorId, pos: RemoteARAnchorPosition(x: pos.x, y: pos.y, z: pos.y))
        }
        
        do {
            let json = try JSONEncoder().encode(RemoteARMapIndex(obj: objPath, map: mapPath, anchors: anchors))
            return String(data: json, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }//func makeInitialARRoomJSON
}
