//
//  LiveVideoEncoder.swift
//  LiveService
//
//  Created by jinnaichen on 2021/5/27.
//

import UIKit
import VideoToolbox

enum LiveVideoProfileLevel {
    case BP
    case MP
    case HP
}

struct LiveVideoEncoderParam {
    var profileLevel: LiveVideoProfileLevel
    var width: Int32
    var height: Int32
    var type: CMVideoCodecType
    var bitRate: Int
    var frameRate: Int
    var maxIFrameInterval: Int
    var allowBFrame: Bool
    
    init() {
        profileLevel = .BP
        type = kCMVideoCodecType_H264
        bitRate = 1024 * 1024
        frameRate = 15
        maxIFrameInterval = 240
        allowBFrame = false
        width = 180
        height = 320
    }
}

protocol LiveVideoEncoderDelegate: NSObjectProtocol {
    func videoEncoderOutput(withData data: Data, isIFrame: Bool)
}

class LiveVideoEncoder: NSObject {
    fileprivate var encoderSession: VTCompressionSession?
    fileprivate var encodeQueue: DispatchQueue?
    
    weak var delegate: LiveVideoEncoderDelegate?
    var encodeParam: LiveVideoEncoderParam?
    
    init(withParam param: LiveVideoEncoderParam) {
        encodeParam = param
        super.init()
    }
    
    func encodeOutputDataCallback() -> Void {
        
    }
}
