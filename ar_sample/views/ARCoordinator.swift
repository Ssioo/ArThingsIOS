//
//  ARContainer.swift
//  ar_sample
//
//  Created by 조연우 on 2021/03/24.
//


import RealityKit
import ARKit
import SwiftUI
import Combine
import QuickLook

class ARCoordinator: NSObject {
    var container: ARViewContainer
    var centerPoint: CGPoint? = nil
    
    //time stamp for capturing period and measuring speed of device
    var timestampForCapture: TimeInterval
    var timestampForDeviceSpeed : TimeInterval
    
    // camera transform stamp for  measuring speed
    var cameraTransformStamp: simd_float4x4
    var cameraEulerAnglesStamp: simd_float3
    var speedOfDevice: Float
    var angularSpeedOfDevice: Float
    var captureQuality : Float
    init(_ container: ARViewContainer) {
        self.container = container
        
        self.timestampForCapture = Date().timeIntervalSince1970
        self.timestampForDeviceSpeed = Date().timeIntervalSince1970
        self.cameraTransformStamp = self.container.arView.cameraTransform.matrix
        self.cameraEulerAnglesStamp = (SIMD3<Float>)(Float(0.0),Float(0.0),Float(0.0))
        self.speedOfDevice = 0
        self.angularSpeedOfDevice = 0
        self.captureQuality = 0


    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let touchInView = sender?.location(in: container.arView), true else {
            return
        }
        
        let tappedObj = container.arView.entity(at: touchInView)
        if tappedObj is ARInfoNode {
            debugPrint("Click ARInfoNode!")
            let parent = (tappedObj as! ARInfoNode).parentNode!
            parent.onTapInfo?(parent)
        } else if tappedObj is ARNode {
            debugPrint("Click ARNode!")
            (tappedObj as! ARNode).onTapNode?(tappedObj as! ARNode)
        } else if tappedObj is ARButton {
            (tappedObj as! ARButton).onTap?(tappedObj as! ARButton)
        } else {
            // Add New Node
            let raycastResult = container.arView.raycast(from: touchInView, allowing: .existingPlaneGeometry, alignment: .any)
            
            guard let firstRayCast = raycastResult.first else { return }
            let pos = firstRayCast.worldTransform.position
            
            container.addButton(pos: pos, text: "ADD Node")
        }
    }
    
    var hasCapturedARNode = false
    var capturedARNode: ARNode? = nil
    var lock = false
    var isUpdatingHarvDataOfCapturedARNode = false
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer? = nil) {
        if self.lock { return }
        self.lock = true
        if sender?.state == UIGestureRecognizer.State.began || sender?.state == UIGestureRecognizer.State.changed {

            // Create Virtual Node in center of the view
            if !self.hasCapturedARNode {
                guard let arNode = container.arView.entity(at: centerPoint!) as? ARNode else {
                    container.vm.alertObject = AlertObject(
                        title: "No ARNode Here",
                        message: "There is no ARNode to select in here. Try Again", onOk: {
                            self.lock = false
                        },
                        onNo: nil)
                    
                    container.vm.isShowAlert = true
                    return
                    
                }
                let raycastResult = container.arView.raycast(
                    from: centerPoint!,
                    allowing: .existingPlaneGeometry,
                    alignment: .any
                )
                guard let firstRayCast = raycastResult.first else {
                    self.lock = false
                    return
                }
                self.hasCapturedARNode = true
                self.capturedARNode = arNode
            }
        } else if (
            sender?.state == UIGestureRecognizer.State.ended
            || sender?.state == UIGestureRecognizer.State.cancelled
            || sender?.state == UIGestureRecognizer.State.failed
        ) {
            self.hasCapturedARNode = false
            if self.capturedARNode != nil {
                let lastPos = container.vm.anchors[self.capturedARNode!]
                container.vm.anchors[self.capturedARNode!] = self.capturedARNode!.position(relativeTo: nil)
                container.vm.updateAnchorsToRemote(
                    currentRoomPath: container.vm.currentRoom,
                    onFail: {
                        self.container.vm.alertObject = AlertObject(
                            title: "Update Fail",
                            message: "Failed to update node's new location",
                            onOk: {
                                self.container.vm.anchors[self.capturedARNode!] = lastPos
                                self.capturedARNode = nil
                            },
                            onNo: nil
                        )
                        self.container.vm.isShowAlert = true
                    },
                    onSuccess: {
                        self.container.vm.alertObject = AlertObject(
                            title: "Update Success",
                            message: "Success to update node's new location",
                            onOk: {
                                self.capturedARNode = nil
                            },
                            onNo: nil
                        )
                        self.container.vm.isShowAlert = true
                    })
            }
        }
        self.lock = false
    }
}

extension ARCoordinator: ARSessionDelegate {
    
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    
  
        // Set CenterPoint
        if self.centerPoint == nil {
            let containerFrame = container.arView.frame
            if !containerFrame.isEmpty {
                self.centerPoint = CGPoint(x: containerFrame.width * 0.5, y: containerFrame.height * 0.5)
                //self.centerPointLeft10 = CGPoint(x: containerFrame.width * 0.5 - 10, y: containerFrame.height * 0.5)
                //self.centerPointBottom10 = CGPoint(x: containerFrame.width * 0.5, y: containerFrame.height * 0.5 + 10)
            }
            return
        }
        
        let cameraPos = self.container.arView.cameraTransform.translation
        
        // Button Look me
        self.container.vm.previousArButton?.lookatMe(cameraPos)
        
        // Node Info Look me
        self.container.vm.anchors.forEach { arNode, pos in
            let infoEntity = arNode.customInfoEntity
            if infoEntity != nil {
                infoEntity!.setPosition([0, 0.1, 0], relativeTo: infoEntity!.parentNode)
                infoEntity!.lookatMe(cameraPos)
            }
        }
        
        if self.hasCapturedARNode {
            // Center Pos Raycast
            let centerPointRaycastResult = container.arView.raycast(
                from: centerPoint!,
                allowing: .estimatedPlane,
                alignment: .any)
            guard let firstCenterPointRaycastResult = centerPointRaycastResult.first else { return }
            self.capturedARNode?.setPosition(firstCenterPointRaycastResult.worldTransform.position, relativeTo: nil)
            if !self.isUpdatingHarvDataOfCapturedARNode {
                self.isUpdatingHarvDataOfCapturedARNode = true
                container.vm.getSolacleHarvDataAt(
                    pos: firstCenterPointRaycastResult.worldTransform.position,
                    onPogress: nil,
                    onRes: {
                        self.capturedARNode?.updateData(newData: $0)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isUpdatingHarvDataOfCapturedARNode = false
                        }
                    }
                )
            }
        
        }
        
        // Center는 커지게
        self.container.vm.anchors.forEach { anchor, pos in
            anchor.focus(false)
        }
        guard let centerObj = self.container.arView.entity(at: centerPoint!) as? ARNode else {
            return
        }
        centerObj.focus(true)
    }
    
    func getImageFolder() -> URL {
        let path = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(container.vm.currentRoom, isDirectory: true)

        if (!FileManager.default.fileExists(atPath: path.path)) {
            do {
                try FileManager.default.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
                
            } catch {
                print(error.localizedDescription);
            }
            
        }
        return path
    }

    func clearImageFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = try! getImageFolder().path
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    struct cameraData: Codable {
        var transform: String
        var projectionMatrix: String
        var intrinsics: String
    }
    
    func MatrixtoString(array: simd_float3x3) -> String? {
        var result: String = "[\n"
        for i in 0..<3 {
            for j in 0..<3{
                if i == 2 && j == 2 {
                    result.append("\(array[i][j])")
                }
                else{
                    result.append("\(array[i][j]),\n")
                }
                
            }
        }
        result.append("]\n")
        return result
    }
    
    func MatrixtoString(array: simd_float4x4) -> String? {
        var result: String = "[\n"
        for i in 0..<4 {
            for j in 0..<4 {
                if i == 3 && j == 3 {
                    result.append("\(array[i][j])\n")
                    
                }
                else{
                    result.append("\(array[i][j]),\n")
                }
            }
        }
        result.append("]")
        return result
    }
  
    func makeCameraInfoJSON(camera: ARCamera) -> String {

        let transform: simd_float4x4 = camera.transform
        let viewMatrix: simd_float4x4 = camera.viewMatrix(for: UIInterfaceOrientation.landscapeLeft)
        let projectionMatrix: simd_float4x4 = camera.projectionMatrix
        let intrinsics: simd_float3x3 = camera.intrinsics
        
        var json :String = "{\n"
        
        json.append("\"transform\" : ")
        var stringMatrix :String = MatrixtoString(array: transform)!
        stringMatrix.append(",\n")
        json.append(stringMatrix)
        
        json.append("\"viewMatrix\" : ")
        stringMatrix = MatrixtoString(array: viewMatrix)!
        stringMatrix.append(",\n")
        json.append(stringMatrix)
        
        json.append("\"projectionMatrix\" : ")
        stringMatrix = MatrixtoString(array: projectionMatrix)!
        stringMatrix.append(",\n")
        json.append(stringMatrix)
        
        json.append("\"intrinsics\" : ")
        stringMatrix=MatrixtoString(array: intrinsics)!
        stringMatrix.append("\n")
        json.append(stringMatrix)
        json.append("}")
        
        return json
        
    
    }

    func uploadToRemote(url: String, content: String, name:String, format:String, path: String){
        APiModule.instance
            .put(
                of: RemotePureFileContent.self,
                //url: "/contents/arthings/\(container.vm.currentRoom)/\(currentTime).json",
                url:url,
                body: [
                    "content":(content),
                    "name":name,
                    "format":format,
                    "type": "file",
                    "path":path
                ],
                onRes: { res in
                    debugPrint("uploaded")

                }
            )// APiModule put
    }
    
    func getSpeedARCam(transform_prev: simd_float4x4, transform:simd_float4x4, deltaT: Float) -> Float{
        var speed: Float
        speed = (transform_prev[3][0] - transform[3][0])*(transform_prev[3][0] - transform[3][0])
        speed +=    (transform_prev[3][1] - transform[3][1])*(transform_prev[3][1] - transform[3][1])
        speed +=    (transform_prev[3][2] - transform[3][2])*(transform_prev[3][2] - transform[3][2])
        speed = sqrt(speed)/deltaT
        return speed
    }
    
    func getAngluarSpeedARCam(rotation_prev: simd_float3, rotation:simd_float3, deltaT: Float) -> Float{
        var speed: Float
        speed = abs(rotation[0]-rotation_prev[0])/deltaT
        speed += abs(rotation[1]-rotation_prev[1])/deltaT
        speed += abs(rotation[2]-rotation_prev[2])/deltaT
        return speed
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        //get current AR Frame
        guard let frame = session.currentFrame else {return}
    
        let currentTime = Date().timeIntervalSince1970
        let currentTransform = frame.camera.transform
        let currentEulerAngles = frame.camera.eulerAngles

        //update speed of device
        speedOfDevice = getSpeedARCam(transform_prev: cameraTransformStamp,transform: currentTransform,deltaT: Float((currentTime - timestampForDeviceSpeed)))
        angularSpeedOfDevice = getAngluarSpeedARCam(rotation_prev: cameraEulerAnglesStamp,rotation: currentEulerAngles, deltaT: Float((currentTime - timestampForDeviceSpeed)))
        captureQuality = 1 - speedOfDevice/10 - angularSpeedOfDevice/100

        //update time stamp and transform of device for speed calculation
        timestampForDeviceSpeed = currentTime
        cameraTransformStamp = currentTransform
        cameraEulerAnglesStamp = currentEulerAngles
        //debugPrint("arSession","speed of device",currentTime,speedOfDevice)
        //debugPrint("arSession","angular speed",currentTime,angularSpeedOfDevice)
        debugPrint("arSession","capture quality : ",captureQuality)
        
        //capture image minimum period is 0.5 seconds
        if container.vm.isCapturing && currentTime - self.timestampForCapture >= 0.5 && captureQuality >= 0.995{
            
            self.timestampForCapture = currentTime
            let pixelBuffer = frame.capturedImage
            let camera = frame.camera
            
            //captured image to ui image to save
            let imageSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext.init(options: nil)
            guard let cgImageRef = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)) else { return }
            let uiImage = UIImage(cgImage: cgImageRef)
            
            // Save image (the same for depth)
            let imagePath = try! getImageFolder().appendingPathComponent("\(currentTime).jpg")
            let imageData = uiImage.jpegData(compressionQuality: 0.9)!
            try! uiImage.jpegData(compressionQuality: 0.9)?.write(to: imagePath)
            
            //사진 upload는 저장할때로 옮겨야할꺼 같다. 여러파일 한방에 올리게
            uploadToRemote(url:"/contents/arthings/\(container.vm.currentRoom)/\(currentTime).json",
                           content:"\(makeCameraInfoJSON(camera:camera))",
                           name:"index.json",
                           format:"text",
                           path:"arthings/\(container.vm.currentRoom)/\(currentTime).json")

            
        }
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {

    }
}

extension String {
    func saveToFile(fileName: String) throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePath = dir.appendingPathComponent(fileName)
    
        do {
            try self.write(to: filePath, atomically: true, encoding: .utf8)
            return filePath
        } catch let e {
            throw e
        }
    }
}

