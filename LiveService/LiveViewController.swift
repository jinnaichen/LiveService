//
//  LiveViewController.swift
//  LiveService
//
//  Created by jinnaichen on 2021/5/27.
//

import UIKit
import AVFoundation

class LiveViewController: UIViewController {
    
    var reverseBtn: UIButton?
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
        
        reverseBtn = UIButton()
        reverseBtn?.layer.cornerRadius = 20
        reverseBtn?.setTitle("翻转", for: .normal)
        reverseBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        reverseBtn?.setTitleColor(.black, for: .normal)
        reverseBtn?.backgroundColor = .white
        reverseBtn?.addTarget(self, action: #selector(reverse), for: .touchUpInside)
        view.addSubview(reverseBtn!) { make in
            make.width.equalTo(60)
            make.height.equalTo(40)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30 - view.safeAreaInsets.bottom)
        }
    }
    
    @objc func reverse() {
        captureService?.reverseCamera()
    }
}

extension LiveViewController: LiveVideoCaptureServiceDelegate {
    func videoCaptureOutput(handleWithData sampleBuffer: CMSampleBuffer) {
        
    }
}
