//
//  LiveVideoCaptureService.swift
//  LiveService
//
//  Created by jinnaichen on 2021/5/27.
//

import UIKit
import AVFoundation
import CoreVideo

struct LiveVideoParam {
    var cameraPosition: AVCaptureDevice.Position
    var sessionPreset: AVCaptureSession.Preset
    var frameRate: Int
    var videoOrientation: AVCaptureVideoOrientation
    
    init() {
        cameraPosition = .front
        sessionPreset = .hd1280x720
        frameRate = 15
        videoOrientation = .portrait
        
        switch UIDevice.current.orientation {
        case .portrait, .portraitUpsideDown:
            videoOrientation = .portrait
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
        case .landscapeRight:
            videoOrientation = .landscapeRight
        default:
            break
        }
    }
}

protocol LiveVideoCaptureServiceDelegate: NSObjectProtocol {
    func videoCaptureOutput(handleWithData sampleBuffer: CMSampleBuffer) -> Void
}

class LiveVideoCaptureService: NSObject {
    weak var delegate: LiveVideoCaptureServiceDelegate?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoParam: LiveVideoParam?
    
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var captureInput: AVCaptureDeviceInput?
    fileprivate var captureVideoOutput: AVCaptureVideoDataOutput?
    fileprivate var captureConnection: AVCaptureConnection?
    fileprivate var isCapture: Bool
    
    convenience override init() {
        let param = LiveVideoParam()
        self.init(withVideoParam: param, completionBlock: nil)
    }
    
    init(withVideoParam videoParam: LiveVideoParam, completionBlock block: ((NSError) -> Void)?) {
        isCapture = false
        super.init()
        
        var error: NSError?
        self.videoParam = videoParam
        
        let cameras = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                            mediaType: .video,
                                                            position: videoParam.cameraPosition)
        // 获取摄像头
        guard let camera = cameras.devices.first else {
            error = NSError(domain: LiveServiceErrorDomain, code: LiveServiceGetCameraError, userInfo: nil)
            block?(error!)
            return
        }
        
        // 创建deviceInput
        guard let input = try? AVCaptureDeviceInput(device: camera) else {
            error = NSError(domain: LiveServiceErrorDomain, code: LiveServiceCreateDeviceInputError, userInfo: nil)
            block?(error!)
            return
        }
        
        let videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        let sampleBufferQueue = DispatchQueue(label: "SampleBufferQueue")
        captureInput = input
        captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput?.videoSettings = videoSettings
        captureVideoOutput?.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        captureVideoOutput?.alwaysDiscardsLateVideoFrames = true
        
        captureSession = AVCaptureSession()
        captureSession?.usesApplicationAudioSession = false
        // 添加输入
        guard captureSession!.canAddInput(captureInput!) else {
            error = NSError(domain: LiveServiceErrorDomain, code: LiveServiceAddDeviceInputError, userInfo: nil)
            block?(error!)
            return
        }
        captureSession!.addInput(captureInput!)
        
        // 添加输出
        guard captureSession!.canAddOutput(captureVideoOutput!) else {
            error = NSError(domain: LiveServiceErrorDomain, code: LiveServiceAddDeviceOutputError, userInfo: nil)
            block?(error!)
            return
        }
        captureSession!.addOutput(captureVideoOutput!)
        
        // 设置分辨率
        guard captureSession!.canSetSessionPreset(videoParam.sessionPreset) else {
            error = NSError(domain: LiveServiceErrorDomain, code: LiveServiceSetPresetError, userInfo: nil)
            block?(error!)
            return
        }
        captureSession!.canSetSessionPreset(videoParam.sessionPreset)
        
        // 前置摄像头镜像
        captureConnection = captureVideoOutput?.connection(with: .video)
        if videoParam.cameraPosition == .front && captureConnection!.isVideoMirroringSupported {
            captureConnection?.isVideoMirrored = true
        }
        captureConnection?.videoOrientation = videoParam.videoOrientation
        
        // 预览
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.connection?.videoOrientation = videoParam.videoOrientation
        previewLayer?.videoGravity = .resizeAspectFill
    }
}

extension LiveVideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}
