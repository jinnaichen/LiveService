//
//  CommonDefine.swift
//  LiveService
//
//  Created by jinnaichen on 2021/6/2.
//

import Foundation
import UIKit
import SnapKit

extension UIView {
    func addSubview(_ subview: UIView, make: (ConstraintMaker) -> Void) {
        addSubview(subview)
        subview.snp.makeConstraints(make)
    }
}
