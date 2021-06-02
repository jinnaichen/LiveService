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

@objc protocol LiveVideoCaptureServiceDelegate: NSObjectProtocol {
    @objc optional func videoCaptureOutput(handleWithData sampleBuffer: CMSampleBuffer)
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
    
    init(withVideoParam videoParam: LiveVideoParam, completionBlock block: ((NSError?) -> Void)?) {
        isCapture = false
        super.init()
        initSettings(withVideoParam: videoParam, completionBlock: block)
    }
    
    func initSettings(withVideoParam videoParam: LiveVideoParam, completionBlock block: ((NSError?) -> Void)?) {
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
        adjustFrameRate(videoParam.frameRate)
        block?(nil)
    }
    
    func startCapture() {
        if isCapture {
            return
        }
        
        captureSession?.startRunning()
        isCapture = true
    }
    
    func stopCapture() {
        captureSession?.stopRunning()
        isCapture = false
    }
    
    @discardableResult
    func adjustFrameRate(_ rate: Int) -> NSError? {
        guard let frameRateRange = captureInput?.device.activeFormat.videoSupportedFrameRateRanges.first else {
            return NSError(domain: LiveServiceErrorDomain, code: LiveServiceGetFrameRateRangeError, userInfo: nil)
        }
        if rate > Int(frameRateRange.maxFrameRate) || rate < Int(frameRateRange.minFrameRate) {
            return NSError(domain: LiveServiceErrorDomain, code: LiveServiceSetFrameRateOutRangeError, userInfo: nil)
        }
        try? captureInput?.device.lockForConfiguration()
        captureInput?.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(rate))
        captureInput?.device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(rate))
        captureInput?.device.unlockForConfiguration()
        return nil
    }
    
    @discardableResult
    func reverseCamera() -> NSError? {
        let currentPosition = captureInput!.device.position
        let toPosition: AVCaptureDevice.Position = (currentPosition == .unspecified || currentPosition == .back) ? .front : .back
        let cameras = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                            mediaType: .video,
                                                            position: toPosition)
        // 获取摄像头
        guard let camera = cameras.devices.first else {
            return NSError(domain: LiveServiceErrorDomain, code: LiveServiceGetCameraError, userInfo: nil)
        }
        
        // 创建deviceInput
        guard let newInput = try? AVCaptureDeviceInput(device: camera) else {
            return NSError(domain: LiveServiceErrorDomain, code: LiveServiceCreateDeviceInputError, userInfo: nil)
        }
        
        captureSession?.beginConfiguration()
        captureSession?.removeInput(captureInput!)
        guard captureSession!.canAddInput(newInput) else {
            return NSError(domain: LiveServiceErrorDomain, code: LiveServiceAddDeviceInputError, userInfo: nil)
        }
        captureInput = newInput
        captureSession!.addInput(captureInput!)
        captureSession?.commitConfiguration()
        captureConnection = captureVideoOutput?.connection(with: .video)
        if toPosition == .front && captureConnection!.isVideoMirroringSupported {
            captureConnection?.isVideoMirrored = true
        }
        captureConnection?.videoOrientation = videoParam!.videoOrientation
        return nil
    }
    
    func changePreset(preset: AVCaptureSession.Preset) {
        videoParam!.sessionPreset = preset
        guard captureSession!.canSetSessionPreset(videoParam!.sessionPreset) else {
            return
        }
        captureSession!.canSetSessionPreset(videoParam!.sessionPreset)
    }
}

// MARK:- AVCaptureVideoDataOutputSampleBufferDelegate

extension LiveVideoCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didDrop sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        delegate?.videoCaptureOutput?(handleWithData: sampleBuffer)
    }
}
