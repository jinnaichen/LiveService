//
//  LiveViewController.swift
//  LiveService
//
//  Created by jinnaichen on 2021/5/27.
//

import UIKit
import AVFoundation

class LiveViewController: UIViewController {
    var captureService: LiveVideoCaptureService?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        let videoParam = LiveVideoParam()
        captureService = LiveVideoCaptureService(withVideoParam: videoParam) { error in
            if error != nil {
                print(error as Any)
            }
        }
        captureService?.delegate = self
        captureService?.previewLayer?.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.layer.addSublayer(captureService!.previewLayer!)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.captureService?.startCapture()
        }
    }
}

extension LiveViewController: LiveVideoCaptureServiceDelegate {
    func videoCaptureOutput(handleWithData sampleBuffer: CMSampleBuffer) {
        
    }
}
